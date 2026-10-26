using System;
using Poks.Core;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Poks
{
    public sealed class CasinoUI : MonoBehaviour
    {
        static readonly Color Ink=new Color(.027f,.025f,.037f,.96f),Gold=new Color(.80f,.65f,.35f),Wine=new Color(.24f,.032f,.075f,.97f),White=new Color(.94f,.90f,.81f);
        Canvas canvas;RectTransform root,screen;Font font;
        Text status,board,hole,log,callLabel,raiseLabel,qualityLabel,error,notice;
        readonly Text[] stacks=new Text[3];Button call,fold,raise,allIn,next;InputField amount;
        public Action<Move,int> ActionRequested;
        public Action NextRequested,MenuRequested,PeekRequested,MuteRequested,QualityRequested;
        public Action ExportRequested;
        public void Initialize()
        {
            font=Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var go=new GameObject("Interface française",typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));go.transform.SetParent(transform);
            canvas=go.GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceOverlay;
            var scaler=go.GetComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=new Vector2(1440,900);scaler.matchWidthOrHeight=.5f;
            root=go.GetComponent<RectTransform>();
            if(EventSystem.current==null)new GameObject("EventSystem",typeof(EventSystem),typeof(StandaloneInputModule));
        }
        RectTransform Rect(Transform parent,string name,float x,float y,float w,float h)
        {
            var go=new GameObject(name,typeof(RectTransform));var r=go.GetComponent<RectTransform>();r.SetParent(parent,false);r.anchorMin=r.anchorMax=new Vector2(0,1);r.pivot=new Vector2(0,1);r.anchoredPosition=new Vector2(x,-y);r.sizeDelta=new Vector2(w,h);return r;
        }
        RectTransform Panel(Transform parent,float x,float y,float w,float h,Color color)
        {
            var r=Rect(parent,"Panneau",x,y,w,h);r.gameObject.AddComponent<Image>().color=color;return r;
        }
        Text Label(Transform parent,string value,float x,float y,float w,float h,int size=21,Color? color=null,TextAnchor align=TextAnchor.MiddleLeft)
        {
            var t=Rect(parent,"Texte",x,y,w,h).gameObject.AddComponent<Text>();t.text=value;t.font=font;t.fontSize=size;t.color=color??White;t.alignment=align;t.raycastTarget=false;t.supportRichText=false;t.horizontalOverflow=HorizontalWrapMode.Wrap;return t;
        }
        Button Button(Transform parent,string value,float x,float y,float w,float h,Action action,out Text text)
        {
            var r=Panel(parent,x,y,w,h,Wine);var b=r.gameObject.AddComponent<Button>();
            var c=b.colors;c.highlightedColor=new Color(1,.83f,.62f);c.pressedColor=new Color(.7f,.5f,.3f);c.disabledColor=new Color(.32f,.29f,.3f,.6f);b.colors=c;
            text=Label(r,value,8,0,w-16,h,20,Gold,TextAnchor.MiddleCenter);b.onClick.AddListener(()=>action?.Invoke());return b;
        }
        Button Button(Transform parent,string value,float x,float y,float w,float h,Action action)=>Button(parent,value,x,y,w,h,action,out _);
        InputField Field(Transform parent,string value,float x,float y,float w,float h,Action<string> changed,bool numeric=false)
        {
            var r=Panel(parent,x,y,w,h,new Color(.09f,.08f,.105f));var field=r.gameObject.AddComponent<InputField>();
            var t=Label(r,value,12,0,w-24,h,20);t.raycastTarget=true;field.textComponent=t;field.characterLimit=numeric?9:48;
            if(numeric)field.contentType=InputField.ContentType.IntegerNumber;
            field.text=value;field.onValueChanged.AddListener(s=>changed(s));return field;
        }
        void Slider(Transform parent,string title,float value,float y,Action<float> changed)
        {
            Label(parent,title,22,y,170,32,18);var track=Panel(parent,205,y+11,275,10,new Color(.25f,.20f,.17f));
            var slider=track.gameObject.AddComponent<Slider>();slider.minValue=0;slider.maxValue=1;
            var fill=Panel(track,0,0,275,10,Gold);fill.anchorMin=Vector2.zero;fill.anchorMax=Vector2.one;fill.offsetMin=fill.offsetMax=Vector2.zero;slider.fillRect=fill;
            var handle=Panel(track,0,-5,18,20,White);handle.pivot=new Vector2(.5f,.5f);slider.handleRect=handle;slider.targetGraphic=handle.GetComponent<Image>();
            slider.value=value;slider.onValueChanged.AddListener(v=>changed(v));
        }
        void Clear()
        {
            if(screen!=null){screen.gameObject.SetActive(false);Destroy(screen.gameObject);}
            screen=Rect(root,"Écran",0,0,1440,900);
        }
        public void Title(Action create,Action quit)
        {
            Clear();var p=Panel(screen,365,205,710,445,Ink);
            Label(p,"POKS CASINO 3D",20,34,670,60,42,Gold,TextAnchor.MiddleCenter);
            Label(p,"LE TOURNOI",20,100,670,52,31,White,TextAnchor.MiddleCenter);
            Label(p,"Le Salon des Prétendants",20,166,670,42,24,Gold,TextAnchor.MiddleCenter);
            Button(p,"CRÉER MON PERSONNAGE / CONTINUER",65,245,580,58,create);
            Button(p,"CRÉDITS",65,320,275,47,()=>Credits(()=>Title(create,quit)));
            Button(p,"QUITTER",370,320,275,47,quit);
            Label(p,"18+ • Jetons fictifs • Jeu hors ligne",30,384,650,35,16,null,TextAnchor.MiddleCenter);
            Label(screen,"VERSION DE DÉVELOPPEMENT UNITY 6 HDRP",35,847,900,30,16,Gold);
        }
        void Credits(Action back)
        {
            Clear();var p=Panel(screen,180,105,1080,690,Ink);
            Label(p,"CRÉDITS & RESSOURCES",30,20,1020,55,34,Gold);
            Label(p,"Fauteuil damassé : © 2021 Wayfair — Eric Chadwick. CC BY 4.0.\nCanapé bois/cuir : © 2024 Darmstadt Graphics Group GmbH — Eric Chadwick, améliorations. CC BY 4.0. Original : Fran Calvente, CC0.\nLampe : © 2021 DGG. CC BY 4.0.\nSheen Chair : © 2020 Wayfair — Eric Chadwick. CC0.\nHumains : dérivés de la base adulte MakeHuman, CC0. Voir les notices des titulaires dans Licenses.\nCes modèles ont été convertis en FBX, leurs matériaux adaptés à HDRP et certaines apparences modifiées. Sources : Khronos glTF Sample Assets et MakeHuman Community.\nSalle, table, cartes, chat, musique et bruitages synthétiques : créations de ce projet. Police DejaVu : licence incluse.\nProminence Poker appartient à ses titulaires ; aucun de ses assets n'est utilisé.",30,97,1020,420,21);
            Button(p,"LICENCE CC BY 4.0",30,548,490,45,()=>Application.OpenURL("https://creativecommons.org/licenses/by/4.0/"));
            Button(p,"RETOUR",550,548,490,45,back);
            Label(p,"Les notices complètes et les liens figurent dans Documentation/ASSETS.md.",30,612,1020,40,18,Gold);
        }
        public void Creator(AvatarProfile profile,Action changed,Action save,Action back)
        {
            Clear();Label(screen,"VOTRE PLACE AU SALON",45,55,790,55,34,Gold);
            Label(screen,"Un personnage adulte, une identité, un tournoi.",45,118,790,40,22);
            Label(screen,"Aperçu 3D de votre avatar assis\nLes réglages sont enregistrés sur ce PC.",45,740,750,80,21);
            var p=Panel(screen,870,30,535,840,Ink);
            Label(p,"CRÉATION DU PERSONNAGE",22,14,490,42,25,Gold);
            Button(p,profile.female?"FEMME":"HOMME",22,65,236,42,()=>{profile.female=!profile.female;if(profile.female)profile.beard=0;changed();Creator(profile,changed,save,back);});
            Button(p,profile.outfit==0?"TENUE DÉCONTRACTÉE":"TENUE HABILLÉE",275,65,238,42,()=>{profile.outfit=1-profile.outfit;changed();Creator(profile,changed,save,back);});
            Label(p,"Prénom",22,116,225,27,16,Gold);Label(p,"Nom",275,116,225,27,16,Gold);
            Field(p,profile.firstName,22,146,236,41,s=>profile.firstName=s);Field(p,profile.lastName,275,146,238,41,s=>profile.lastName=s);
            Label(p,"Surnom",22,194,225,27,16,Gold);Label(p,"Pays",275,194,225,27,16,Gold);
            Field(p,profile.nickname,22,224,236,41,s=>profile.nickname=s);Field(p,profile.country,275,224,238,41,s=>profile.country=s);
            string[] hair={"Crâne rasé","Court","Mi-long","Volume","Coiffé en arrière"};
            Button(p,"Coiffure : "+hair[profile.hair]+"  ›",22,285,491,42,()=>{profile.hair=(profile.hair+1)%5;changed();Creator(profile,changed,save,back);});
            string[] beards={"Sans barbe","Barbe courte","Bouc"};
            Button(p,profile.female?"Barbe : sans objet":"Barbe : "+beards[profile.beard]+"  ›",22,338,491,42,()=>{if(!profile.female){profile.beard=(profile.beard+1)%3;changed();Creator(profile,changed,save,back);}});
            Slider(p,"Morphologie",profile.build,406,v=>{profile.build=v;changed();});
            Slider(p,"Yeux",profile.eyes,453,v=>{profile.eyes=v;changed();});
            Slider(p,"Nez",profile.nose,500,v=>{profile.nose=v;changed();});
            Slider(p,"Bouche",profile.mouth,547,v=>{profile.mouth=v;changed();});
            Slider(p,"Mâchoire",profile.jaw,594,v=>{profile.jaw=v;changed();});
            Slider(p,"Forme du visage",profile.face,641,v=>{profile.face=v;changed();});
            error=Label(p,"",22,686,491,48,17,new Color(1,.5f,.4f));
            Button(p,"ENTRER DANS LE TOURNOI",22,744,491,49,()=>{
                profile.Normalize();if(string.IsNullOrWhiteSpace(profile.firstName)||string.IsNullOrWhiteSpace(profile.lastName)||string.IsNullOrWhiteSpace(profile.country)){error.text="Renseignez prénom, nom et pays.";return;}save();
            });
            Button(screen,"RETOUR",45,640,200,48,back);
        }
        public void Loading()
        {
            Clear();var p=Panel(screen,280,300,880,260,Ink);
            Label(p,"LE SALON DES PRÉTENDANTS",30,25,820,55,30,Gold,TextAnchor.MiddleCenter);
            Label(p,"Remportez ce tournoi pour obtenir votre carte de membre noire et dorée et vous qualifier pour le futur Grand Poks Casino 3D.",45,100,790,108,25,null,TextAnchor.MiddleCenter);
        }
        public void Game()
        {
            Clear();var top=Panel(screen,20,15,1400,105,Ink);
            status=Label(top,"",20,5,1110,40,24,Gold);
            for(int i=0;i<3;i++)stacks[i]=Label(top,"",20+i*365,49,360,45,20);
            Button(top,"MENU",1220,17,160,40,()=>MenuRequested?.Invoke());
            Button(top,"SON",1130,65,110,30,()=>MuteRequested?.Invoke());
            Button(top,"RENDU ÉLEVÉ",1250,65,130,30,()=>QualityRequested?.Invoke(),out qualityLabel);
            var history=Panel(screen,1150,140,270,390,new Color(Ink.r,Ink.g,Ink.b,.83f));Label(history,"HISTORIQUE",15,7,245,35,19,Gold);log=Label(history,"",15,48,240,328,16);
            board=Label(screen,"",210,615,890,42,27,Gold,TextAnchor.MiddleCenter);
            hole=Label(screen,"",210,663,890,40,24,null,TextAnchor.MiddleCenter);
            var p=Panel(screen,20,720,1400,160,Ink);
            fold=Button(p,"PASSER",20,18,190,53,()=>ActionRequested?.Invoke(Move.Fold,0));
            call=Button(p,"SUIVRE",225,18,215,53,()=>ActionRequested?.Invoke(Move.Call,0),out callLabel);
            raise=Button(p,"RELANCER À",455,18,220,53,()=>{if(int.TryParse(amount.text,out int value))ActionRequested?.Invoke(Move.Raise,value);},out raiseLabel);
            amount=Field(p,"40",690,18,160,53,_=>{},true);
            allIn=Button(p,"TAPIS",865,18,160,53,()=>ActionRequested?.Invoke(Move.Raise,int.MaxValue));
            next=Button(p,"MAIN SUIVANTE",1040,18,335,53,()=>NextRequested?.Invoke());
            Button(p,"VOIR / CACHER MES CARTES",20,91,340,43,()=>PeekRequested?.Invoke());
            Label(p,"Clic gauche maintenu : regarder à 360° • Molette : distance • Échap : caméra initiale",385,88,990,49,17);
        }
        public void Quality(bool high){if(qualityLabel!=null)qualityLabel.text=high?"RENDU ÉLEVÉ":"RENDU FLUIDE";}
        public void UpdateGame(Tournament g,bool busy,bool peek)
        {
            if(status==null)return;
            status.text=$"LE SALON DES PRÉTENDANTS   •   Main {g.Hand}   •   Blindes {g.SmallBlind}/{g.BigBlind}   •   Pot {g.Pot}";
            for(int i=0;i<3;i++)stacks[i].text=(g.Actor==i?"▶ ":"")+g.Seats[i].Name+"  ·  "+g.Seats[i].Stack+(g.Seats[i].Folded?"  (passé)":"");
            bool human=!busy&&!g.Finished&&g.Actor==0;call.interactable=fold.interactable=human;raise.interactable=human&&g.CanRaise(0);allIn.interactable=human&&(g.CanRaise(0)||g.ToCall(0)>=g.Seats[0].Stack);amount.interactable=raise.interactable;
            callLabel.text=g.ToCall(0)==0?"PAROLE":"SUIVRE "+Math.Min(g.ToCall(0),g.Seats[0].Stack);
            raiseLabel.text=g.CurrentBet==0?"MISER À":"RELANCER À";
            if(!amount.isFocused)amount.text=Math.Min(g.MinRaise,g.MaxRaise(0)).ToString();
            next.interactable=!busy&&g.Finished&&!g.Complete;
            board.text=g.Finished?g.Result:string.Join("   ",g.Board.ConvertAll(Cards.Label));
            hole.text=peek?"VOS CARTES : "+string.Join("  ",Array.ConvertAll(g.Seats[0].Hole,Cards.Label)):"VOS CARTES : ▧  ▧";
            int start=Math.Max(0,g.Log.Count-10);log.text=string.Join("\n",g.Log.GetRange(start,g.Log.Count-start));
        }
        public void Error(string message){if(error!=null)error.text=message;else if(status!=null)status.text=message;}
        public void Notice(string message){if(notice!=null)notice.text=message;}
        public RectTransform Member(Membership member,Texture portrait,Action back)
        {
            Clear();var p=Panel(screen,235,160,970,550,Ink);
            Panel(p,0,0,970,5,Gold);Panel(p,0,545,970,5,Gold);
            Label(p,"POKS CASINO 3D",35,24,900,55,35,Gold);
            Label(p,"CARTE DE MEMBRE  •  LE TOURNOI",35,85,900,40,22,Gold);
            var photo=Rect(p,"Portrait de l'avatar",35,150,245,305).gameObject.AddComponent<RawImage>();photo.texture=portrait;photo.color=Color.white;
            var id=member.identity;
            Label(p,id.firstName+" "+id.lastName,315,154,620,55,30,White);
            Label(p,"« "+id.nickname+" »\nPays : "+id.country+"\nMembre : "+member.number,315,223,620,130,23,White);
            Label(p,"QUALIFIÉ\nFUTUR GRAND POKS CASINO 3D",315,365,620,90,27,Gold);
            Label(p,"Le Salon des Prétendants • "+member.qualifiedAtUtc,35,480,900,35,17,Gold);
            Button(screen,"EXPORTER MA CARTE PNG + IDENTITÉ JSON",235,750,650,55,()=>ExportRequested?.Invoke());
            Button(screen,"RETOUR",905,750,300,55,back);notice=Label(screen,"Carte enregistrée localement après votre victoire.",235,815,970,60,18,Gold);return p;
        }
        public void Defeat(Action restart,Action menu)
        {
            Clear();var p=Panel(screen,380,250,680,390,Ink);
            Label(p,"TOURNOI TERMINÉ",25,30,630,60,35,Gold,TextAnchor.MiddleCenter);
            Label(p,"Votre tapis est épuisé. Une nouvelle tentative vous attend au Salon des Prétendants.",40,120,600,90,24,null,TextAnchor.MiddleCenter);
            Button(p,"NOUVEAU TOURNOI",40,250,600,50,restart);Button(p,"MENU",200,320,280,43,menu);
        }
    }
}
