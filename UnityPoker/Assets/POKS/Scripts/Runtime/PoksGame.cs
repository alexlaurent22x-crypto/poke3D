using System;
using System.Collections;
using System.IO;
using Poks.Core;
using UnityEngine;

namespace Poks
{
    public sealed class PoksGame : MonoBehaviour
    {
        SalonScene salon;CasinoUI ui;CasinoAudio audioBus;TablePresentation table;
        AvatarProfile profile;Tournament game;
        bool busy,peek=true,playing,high=true,avatarFemale;
        Membership membership;Texture2D portrait;RectTransform memberRect;
        string fatal;
        void Start()
        {
            try {
                profile=AvatarProfile.Load();avatarFemale=profile.female;
                salon=new GameObject("Le Salon des Prétendants").AddComponent<SalonScene>();salon.Build(profile);
                table=new GameObject("Cartes et jetons").AddComponent<TablePresentation>();table.Initialize();
                audioBus=gameObject.AddComponent<CasinoAudio>();ui=gameObject.AddComponent<CasinoUI>();ui.Initialize();
                ui.ActionRequested=HumanAction;ui.NextRequested=()=>StartCoroutine(Deal());ui.MenuRequested=ShowTitle;
                ui.PeekRequested=()=>{peek=!peek;Refresh();};ui.MuteRequested=()=>audioBus.Toggle();
                ui.QualityRequested=()=>{high=!high;salon.SetQuality(high);ui.Quality(high);};
                ui.ExportRequested=()=>StartCoroutine(ExportCard());ShowTitle();
            } catch(Exception e){fatal=e.ToString();Debug.LogException(e);}
        }
        void OnGUI()
        {
            if(fatal==null)return;GUI.color=Color.white;
            GUI.Box(new Rect(20,20,Screen.width-40,Screen.height-40),"POKS — Initialisation interrompue");
            GUI.Label(new Rect(40,65,Screen.width-80,Screen.height-100),fatal+"\n\nDans Unity : POKS > Préparer le projet, puis relancer Play. Consultez aussi Console.");
        }
        void ShowTitle()
        {
            StopAllCoroutines();playing=false;busy=false;salon.Orbit.SetPlay(false);table.Clear();ui.Title(ShowCreator,()=>Application.Quit());
        }
        void ShowCreator()
        {
            salon.Orbit.Portrait();ui.Creator(profile,UpdateAvatar,()=>{
                try{profile.Save();StartCoroutine(BeginTournament());}catch(Exception e){ui.Error("Enregistrement impossible : "+e.Message);Debug.LogException(e);}
            },ShowTitle);
        }
        void UpdateAvatar()
        {
            if(avatarFemale!=profile.female){avatarFemale=profile.female;salon.ReplaceAvatar(profile);}
            else salon.Players[0].Configure(profile);
        }
        IEnumerator BeginTournament()
        {
            ui.Loading();salon.Orbit.SetPlay(false);audioBus.Speak("welcome");yield return new WaitForSeconds(2.5f);
            game=new Tournament(profile.DisplayName);playing=true;peek=true;membership=null;
            salon.Orbit.SetPlay(true);ui.Game();ui.Quality(high);yield return Deal();
        }
        IEnumerator Deal()
        {
            if(busy||game==null||!game.Finished)yield break;
            busy=true;
            if(!game.StartHand()){busy=false;yield break;}
            table.Clear();salon.Dealer.Gesture();audioBus.Speak("deal");audioBus.Play("card");Refresh();
            yield return new WaitForSeconds(1.2f);busy=false;Refresh();yield return RunAI();
        }
        void HumanAction(Move move,int target)
        {
            if(busy||game==null||game.Finished||game.Actor!=0)return;
            if(move==Move.Raise&&target==int.MaxValue){if(game.CanRaise(0))target=game.MaxRaise(0);else move=Move.Call;}
            var before=game.Street;int count=game.Board.Count;
            if(!game.Act(move,target)){ui.Error($"Relance invalide : minimum {game.MinRaise}, maximum {game.MaxRaise(0)}. Le tapis court reste autorisé.");return;}
            salon.Players[0].Gesture();audioBus.Play(move==Move.Fold?"card":"chips");AnimateStreet(before,count);Refresh();if(move!=Move.Fold)table.BetGesture(0);StartCoroutine(AfterHuman());
        }
        IEnumerator AfterHuman(){busy=true;Refresh();yield return new WaitForSeconds(.65f);busy=false;yield return RunAI();}
        IEnumerator RunAI()
        {
            while(playing&&!game.Finished&&game.Actor>0) {
                busy=true;Refresh();yield return new WaitForSeconds(UnityEngine.Random.Range(1.0f,1.7f));
                int who=game.Actor;var before=game.Street;int count=game.Board.Count;
                if(!game.ActAI())throw new InvalidOperationException("L'IA n'a pas produit d'action légale");
                salon.Players[who].Gesture();audioBus.Play(game.Seats[who].Folded?"card":"chips");AnimateStreet(before,count);Refresh();if(!game.Seats[who].Folded)table.BetGesture(who);
                yield return new WaitForSeconds(.65f);
            }
            busy=game.Finished;Refresh();
            if(game.Finished) {
                audioBus.Speak("showdown");yield return new WaitForSeconds(2.5f);
                busy=false;
                if(game.Complete) {
                    playing=false;
                    if(game.Winner==0)yield return Award();else ui.Defeat(()=>StartCoroutine(BeginTournament()),ShowTitle);
                } else if(game.Seats[0].Stack==0){playing=false;ui.Defeat(()=>StartCoroutine(BeginTournament()),ShowTitle);}
                else Refresh();
            }
        }
        void AnimateStreet(Street before,int oldCount)
        {
            if(game.Board.Count>oldCount){salon.Dealer.Gesture();audioBus.Play("card");audioBus.Speak(game.Board.Count==3?"flop":game.Board.Count==4?"turn":"river");}
        }
        void Refresh()
        {
            if(game==null)return;table.Sync(game,peek);ui.UpdateGame(game,busy,peek);
        }
        void Update(){if(playing&&Input.GetKeyDown(KeyCode.V)){peek=!peek;Refresh();}}
        IEnumerator Award()
        {
            audioBus.Speak("victory");salon.Orbit.Portrait();ui.Loading();
            // Hide overlay for one rendered portrait. ReadPixels captures actual rendered pixels, not a fabricated avatar.
            var canvas=ui.GetComponentInChildren<Canvas>();if(canvas!=null)canvas.enabled=false;
            yield return new WaitForEndOfFrame();
            int w=Mathf.Max(1,Mathf.RoundToInt(Screen.height*.55f)),h=Mathf.Max(1,Mathf.RoundToInt(Screen.height*.75f));
            w=Mathf.Min(w,Screen.width);h=Mathf.Min(h,Screen.height);
            portrait=new Texture2D(w,h,TextureFormat.RGB24,false);portrait.ReadPixels(new Rect((Screen.width-w)/2,(Screen.height-h)/2,w,h),0,0);portrait.Apply();
            if(canvas!=null)canvas.enabled=true;
            membership=new Membership{identity=JsonUtility.FromJson<AvatarProfile>(JsonUtility.ToJson(profile)),number="POKS-"+Guid.NewGuid().ToString("N").Substring(0,12).ToUpperInvariant(),qualifiedAtUtc=DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm 'UTC'")};
            try {
                string dir=Path.Combine(Application.persistentDataPath,"Membership");Directory.CreateDirectory(dir);
                File.WriteAllText(Path.Combine(dir,membership.number+".json"),JsonUtility.ToJson(membership,true));
                File.WriteAllBytes(Path.Combine(dir,membership.number+"-avatar.png"),portrait.EncodeToPNG());
            }catch(Exception e){Debug.LogError("Sauvegarde de qualification : "+e.Message);}
            memberRect=ui.Member(membership,portrait,ShowTitle);yield return new WaitForEndOfFrame();yield return ExportCard();
        }
        IEnumerator ExportCard()
        {
            if(memberRect==null||membership==null)yield break;
            yield return new WaitForEndOfFrame();
            var corners=new Vector3[4];memberRect.GetWorldCorners(corners);
            int x=Mathf.Clamp(Mathf.RoundToInt(corners[0].x),0,Screen.width-1),y=Mathf.Clamp(Mathf.RoundToInt(corners[0].y),0,Screen.height-1);
            int w=Mathf.Clamp(Mathf.RoundToInt(corners[2].x-corners[0].x),1,Screen.width-x),h=Mathf.Clamp(Mathf.RoundToInt(corners[2].y-corners[0].y),1,Screen.height-y);
            var png=new Texture2D(w,h,TextureFormat.RGB24,false);png.ReadPixels(new Rect(x,y,w,h),0,0);png.Apply();
            string path=Path.Combine(Application.persistentDataPath,"Membership",membership.number+".png");
            try{Directory.CreateDirectory(Path.GetDirectoryName(path));File.WriteAllBytes(path,png.EncodeToPNG());Debug.Log("Carte de membre enregistrée : "+path);ui.Notice("Carte enregistrée : "+path);}
            catch(Exception e){Debug.LogError("Export PNG : "+e.Message);}Destroy(png);
        }
    }
}
