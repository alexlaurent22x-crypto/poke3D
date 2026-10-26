using System.Collections.Generic;
using System.Linq;
using Poks.Core;
using UnityEngine;

namespace Poks
{
    public sealed class TablePresentation : MonoBehaviour
    {
        readonly Dictionary<string,GameObject> cards=new Dictionary<string,GameObject>();
        readonly Dictionary<string,Material> faces=new Dictionary<string,Material>();
        readonly List<GameObject> chips=new List<GameObject>();
        Mesh cardMesh;
        Material[] chipMats;
        public void Initialize()
        {
            cardMesh=new Mesh{name="Carte rectangulaire UV"};
            cardMesh.vertices=new[]{new Vector3(-.085f,0,-.13f),new Vector3(-.085f,0,.13f),new Vector3(.085f,0,.13f),new Vector3(.085f,0,-.13f)};
            cardMesh.uv=new[]{new Vector2(0,0),new Vector2(0,1),new Vector2(1,1),new Vector2(1,0)};
            cardMesh.triangles=new[]{0,1,2,0,2,3};cardMesh.RecalculateNormals();cardMesh.RecalculateBounds();
            chipMats=new[]{ArtMaterials.Make("Jeton bordeaux",new Color(.42f,.018f,.06f),.15f,.5f),ArtMaterials.Make("Jeton ivoire",new Color(.8f,.73f,.54f),.1f,.45f),ArtMaterials.Make("Jeton noir",new Color(.015f,.02f,.028f),.2f,.4f)};
        }
        Material Face(int c)
        {
            string name=c<0?"back":c.ToString("00");if(faces.TryGetValue(name,out var m))return m;
            m=ArtMaterials.Make("Carte "+name,Color.white,0,.25f);m.SetTexture("_BaseColorMap",Resources.Load<Texture2D>("Cards/"+name));faces[name]=m;return m;
        }
        public void Sync(Tournament game,bool peek)
        {
            var alive=new HashSet<string>();
            for(int seat=0;seat<3;seat++)for(int k=0;k<game.Seats[seat].Hole.Length;k++) {
                var p=game.Seats[seat];bool reveal=seat==0?peek:game.Finished&&!p.Folded;
                Vector3 at=seat==0?new Vector3((k-.5f)*.21f,.93f,-.65f):new Vector3((seat==1?-.96f:.96f)+(k-.5f)*.21f,.93f,.38f);
                Put("seat"+seat+"_"+k,reveal?p.Hole[k]:-1,at,seat==0?0:seat==1?120:-120,alive);
            }
            for(int k=0;k<game.Board.Count;k++)Put("board"+k,game.Board[k],new Vector3((k-2)*.205f,.925f,-.04f),0,alive);
            foreach(var key in cards.Keys.Where(k=>!alive.Contains(k)).ToArray()){Destroy(cards[key]);cards.Remove(key);}
            foreach(var c in chips)Destroy(c);chips.Clear();
            for(int seat=0;seat<3;seat++) {
                int count=Mathf.Clamp(Mathf.CeilToInt(game.Seats[seat].Stack/70f),0,15);
                for(int i=0;i<count;i++)Chip(new Vector3((seat-1)*.75f+(i/6)*.075f,.925f+(i%6)*.018f,seat==0?-.40f:.57f),seat);
            }
            for(int i=0;i<Mathf.Min(18,Mathf.CeilToInt(game.Pot/30f));i++)Chip(new Vector3(.48f+(i/6)*.08f,.925f+(i%6)*.018f,-.35f),i%3);
        }
        void Put(string key,int card,Vector3 at,float yaw,HashSet<string> alive)
        {
            alive.Add(key);
            if(!cards.TryGetValue(key,out var go)) {
                go=new GameObject(key,typeof(MeshFilter),typeof(MeshRenderer));go.transform.SetParent(transform);go.GetComponent<MeshFilter>().sharedMesh=cardMesh;
                go.transform.position=new Vector3(0,1.05f,1.05f);go.transform.rotation=Quaternion.Euler(0,yaw,0);go.AddComponent<CardSlide>().Begin(at);cards[key]=go;
            }
            go.GetComponent<MeshRenderer>().sharedMaterial=Face(card);
        }
        void Chip(Vector3 at,int type)
        {
            var go=GameObject.CreatePrimitive(PrimitiveType.Cylinder);go.name="Jeton";go.transform.SetParent(transform);go.transform.position=at;go.transform.localScale=new Vector3(.062f,.008f,.062f);go.GetComponent<Renderer>().sharedMaterial=chipMats[type];Destroy(go.GetComponent<Collider>());chips.Add(go);
        }
        public void BetGesture(int seat)
        {
            var from=seat==0?new Vector3(0,.96f,-.63f):new Vector3(seat==1?-.95f:.95f,.96f,.45f);
            for(int i=0;i<3;i++) {
                var go=GameObject.CreatePrimitive(PrimitiveType.Cylinder);go.name="Jeton animé";go.transform.SetParent(transform);go.transform.position=from+Vector3.up*i*.018f;go.transform.localScale=new Vector3(.062f,.008f,.062f);go.GetComponent<Renderer>().sharedMaterial=chipMats[seat];Destroy(go.GetComponent<Collider>());
                go.AddComponent<CardSlide>().Begin(new Vector3(.5f+i*.05f,.95f,-.33f));Destroy(go,.7f);
            }
        }
        public void Clear(){foreach(var c in cards.Values)Destroy(c);cards.Clear();foreach(var c in chips)Destroy(c);chips.Clear();}
    }
    public sealed class CardSlide : MonoBehaviour
    {
        Vector3 from,to;float start;public void Begin(Vector3 target){from=transform.position;to=target;start=Time.time;}
        void Update(){float t=Mathf.Clamp01((Time.time-start)/.55f);transform.position=Vector3.Lerp(from,to,t*t*(3-2*t));if(t>=1)Destroy(this);}
    }
}
