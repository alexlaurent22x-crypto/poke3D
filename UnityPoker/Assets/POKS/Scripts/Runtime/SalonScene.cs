using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;

namespace Poks
{
    public sealed class SalonScene : MonoBehaviour
    {
        public Camera Camera {get;private set;}
        public SeatedOrbitCamera Orbit {get;private set;}
        public AvatarActor[] Players {get;}=new AvatarActor[3];
        public AvatarActor Dealer {get;private set;}
        public readonly Vector3[] Seats={new Vector3(0,0,-1.65f),new Vector3(-1.50f,0,.88f),new Vector3(1.50f,0,.88f)};
        readonly float[] angles={0,120,-120};
        public void Build(AvatarProfile profile)
        {
            Application.targetFrameRate=60;QualitySettings.vSyncCount=0;
            var room=ArtMaterials.Spawn("Salon",Vector3.zero,Quaternion.identity,transform);
            foreach(var t in room.GetComponentsInChildren<Transform>())if(t.name.StartsWith("Banquette")||t.name.StartsWith("TuftButton"))t.gameObject.SetActive(false);
            Furniture("SheenWoodLeatherSofa",new Vector3(0,0,-5.7f),0,1.12f);
            Furniture("LightsPunctualLamp",new Vector3(3.3f,0,-5.5f),0,1.55f);
            ArtMaterials.Spawn("PokerTable",Vector3.zero,Quaternion.identity,transform);
            for(int i=0;i<3;i++)Chair(Seats[i],angles[i]);
            ReplaceAvatar(profile);
            Players[1]=Person("AvatarMale",Seats[1],angles[1]);Players[1].TintOutfit(new Color(.24f,.018f,.045f));
            Players[2]=Person("OpponentFemale",Seats[2],angles[2]);Players[2].TintOutfit(new Color(.012f,.012f,.018f));
            Accessories(Players[1],false);Accessories(Players[2],true);
            Dealer=Person("Dealer",new Vector3(0,0,1.75f),180);Chair(new Vector3(0,0,1.75f),180);
            // Ambient cast uses supplied seated rigs; standing rigs are selected when present.
            Person("GuardMale",new Vector3(-2.1f,0,6.0f),180);
            Person("GuardMale",new Vector3(2.1f,0,6.0f),180);
            Person("BartenderFemale",new Vector3(-5.65f,0,1.0f),90).gameObject.AddComponent<AmbientGesture>();
            Person("AvatarMale",new Vector3(-1.0f,0,-5.7f),20);
            Person("AvatarFemale",new Vector3(.9f,0,-5.7f),-20);
            var supervisor=Person("AvatarFemale",new Vector3(4.65f,0,3.25f),180);
            supervisor.gameObject.AddComponent<AmbientGesture>();Chair(new Vector3(4.65f,0,3.25f),180);
            var cat=ArtMaterials.Spawn("SleepingCat",new Vector3(.8f,.67f,-5.52f),Quaternion.Euler(0,12,0),transform);cat.AddComponent<CatBreathing>();
            SetupLighting();
            var probeObject=new GameObject("Reflets du salon",typeof(ReflectionProbe),typeof(HDAdditionalReflectionData));probeObject.transform.SetParent(transform);probeObject.transform.position=new Vector3(0,1.8f,0);
            var probe=probeObject.GetComponent<ReflectionProbe>();probe.mode=ReflectionProbeMode.Realtime;probe.refreshMode=ReflectionProbeRefreshMode.OnAwake;probe.timeSlicingMode=ReflectionProbeTimeSlicingMode.AllFacesAtOnce;probe.resolution=128;probe.size=new Vector3(13,5,13);probe.boxProjection=true;
            var hdProbe=probeObject.GetComponent<HDAdditionalReflectionData>();hdProbe.mode=ProbeSettings.Mode.Realtime;hdProbe.realtimeMode=ProbeSettings.RealtimeMode.OnDemand;hdProbe.RequestRenderNextUpdate();
            var cam=new GameObject("Caméra assise",typeof(Camera),typeof(AudioListener),typeof(HDAdditionalCameraData));cam.transform.SetParent(transform);
            Camera=cam.GetComponent<Camera>();Camera.nearClipPlane=.06f;Camera.farClipPlane=60;Camera.fieldOfView=55;
            cam.GetComponent<HDAdditionalCameraData>().antialiasing=HDAdditionalCameraData.AntialiasingMode.TemporalAntialiasing;
            Orbit=cam.AddComponent<SeatedOrbitCamera>();Orbit.SetPlay(false);
            var tv=new GameObject("Programme TV — classement du tournoi",typeof(TextMesh));tv.transform.SetParent(transform);tv.transform.position=new Vector3(6.43f,2.63f,-2.2f);tv.transform.rotation=Quaternion.Euler(0,90,0);
            var text=tv.GetComponent<TextMesh>();text.text="POKS TV\nLE TOURNOI\nSALON VIP • EN DIRECT";text.characterSize=.07f;text.fontSize=44;text.anchor=TextAnchor.MiddleCenter;text.color=new Color(.92f,.74f,.32f);
        }
        void Chair(Vector3 position,float yaw)=>Furniture("ChairDamask",position,yaw,1.07f);
        void Furniture(string source,Vector3 position,float yaw,float height)
        {
            var go=ArtMaterials.Spawn(source,position,Quaternion.Euler(0,yaw,0),transform);
            var renderers=go.GetComponentsInChildren<Renderer>();var b=new Bounds(position,Vector3.zero);foreach(var r in renderers)b.Encapsulate(r.bounds);
            float scale=height/Mathf.Max(.01f,b.size.y);go.transform.localScale*=scale;
            // Recompute bounds after scale; place imported chair base on the floor.
            bool first=true;foreach(var r in renderers){if(first){b=r.bounds;first=false;}else b.Encapsulate(r.bounds);}
            go.transform.position+=Vector3.up*(-b.min.y);
        }
        AvatarActor Person(string source,Vector3 at,float yaw)
        {
            var go=ArtMaterials.Spawn(source,at,Quaternion.Euler(0,yaw+180,0),transform);
            go.transform.localScale*=.72f;
            if(source=="GuardMale"||source=="BartenderFemale")go.transform.position+=Vector3.up*.36f;
            var actor=go.AddComponent<AvatarActor>();actor.Initialize(source);
            // Hide optional appearance meshes on NPCs; originals retain their authored hair.
            foreach(var t in go.GetComponentsInChildren<Transform>(true))if(t.name.StartsWith("HairOption")||t.name.StartsWith("BeardOption"))t.gameObject.SetActive(false);
            return actor;
        }
        public void ReplaceAvatar(AvatarProfile profile)
        {
            if(Players[0]!=null){Players[0].gameObject.SetActive(false);Destroy(Players[0].gameObject);}
            Players[0]=Person(profile.female?"AvatarFemale":"AvatarMale",Seats[0],angles[0]);Players[0].Configure(profile);
        }
        void Accessories(AvatarActor actor,bool hat)
        {
            Transform head=null;foreach(var t in actor.GetComponentsInChildren<Transform>())if(t.name=="head"){head=t;break;}
            if(head==null)return;
            var black=ArtMaterials.Make("Accessoire noir",new Color(.009f,.008f,.012f),.1f,.3f);
            if(hat) {
                Accessory(PrimitiveType.Cylinder,"Chapeau noir — bord",head,new Vector3(0,.14f,0),new Vector3(.30f,.012f,.27f),black);
                Accessory(PrimitiveType.Cylinder,"Chapeau noir — calotte",head,new Vector3(0,.18f,0),new Vector3(.20f,.055f,.19f),black);
            } else {
                Accessory(PrimitiveType.Sphere,"Verre solaire gauche",head,new Vector3(-.045f,.055f,.10f),new Vector3(.075f,.045f,.012f),black);
                Accessory(PrimitiveType.Sphere,"Verre solaire droit",head,new Vector3(.045f,.055f,.10f),new Vector3(.075f,.045f,.012f),black);
            }
        }
        void Accessory(PrimitiveType type,string name,Transform parent,Vector3 p,Vector3 scale,Material material)
        {
            var go=GameObject.CreatePrimitive(type);go.name=name;go.transform.SetParent(parent,false);go.transform.localPosition=p;go.transform.localScale=scale;go.GetComponent<Renderer>().sharedMaterial=material;Destroy(go.GetComponent<Collider>());
        }
        void SetupLighting()
        {
            var volume=new GameObject("Ambiance HDRP",typeof(Volume)).GetComponent<Volume>();volume.transform.SetParent(transform);volume.isGlobal=true;
            var profile=ScriptableObject.CreateInstance<VolumeProfile>();volume.sharedProfile=profile;
            var visual=profile.Add<VisualEnvironment>(true);visual.skyType.Override((int)SkyType.Gradient);
            var sky=profile.Add<GradientSky>(true);sky.top.Override(new Color(.07f,.055f,.045f));sky.middle.Override(new Color(.11f,.085f,.065f));sky.bottom.Override(new Color(.035f,.025f,.03f));
            profile.Add<Exposure>(true).mode.Override(ExposureMode.Fixed);profile.TryGet<Exposure>(out var exposure);exposure.fixedExposure.Override(5.5f);
            profile.Add<Tonemapping>(true).mode.Override(TonemappingMode.ACES);
            profile.Add<Bloom>(true).intensity.Override(.14f);
            var sun=new GameObject("Lumière de remplissage",typeof(Light));sun.transform.SetParent(transform);sun.transform.rotation=Quaternion.Euler(48,-35,0);
            var l=sun.GetComponent<Light>();l.type=LightType.Directional;l.color=new Color(1,.82f,.64f);l.intensity=500;l.shadows=LightShadows.None;sun.AddComponent<HDAdditionalLightData>();
            AddLight("Lustre",new Vector3(0,3.4f,0),new Color(1,.72f,.42f),2200,10,true);
            AddLight("Table",new Vector3(0,2.8f,.3f),new Color(1,.89f,.72f),1500,5,true);
            AddLight("Bar",new Vector3(-5,2.8f,1),new Color(1,.60f,.28f),1300,5,false);
            AddLight("Porte",new Vector3(0,3.5f,5.8f),new Color(1,.74f,.32f),950,5,false);
            AddLight("Salon",new Vector3(0,2.7f,-4.8f),new Color(.6f,.67f,1),700,5,false);
        }
        void AddLight(string name,Vector3 at,Color color,float intensity,float range,bool shadows)
        {
            var go=new GameObject(name,typeof(Light));go.transform.SetParent(transform);go.transform.position=at;
            var l=go.GetComponent<Light>();l.type=LightType.Point;l.color=color;l.range=range;l.intensity=intensity;l.shadows=shadows?LightShadows.Soft:LightShadows.None;go.AddComponent<HDAdditionalLightData>();
        }
        public void SetQuality(bool high)
        {
            foreach(var light in GetComponentsInChildren<Light>())if(light.name=="Lustre"||light.name=="Table")light.shadows=high?LightShadows.Soft:LightShadows.None;
            Camera.GetComponent<HDAdditionalCameraData>().antialiasing=high?HDAdditionalCameraData.AntialiasingMode.TemporalAntialiasing:HDAdditionalCameraData.AntialiasingMode.FastApproximateAntialiasing;
        }
    }
    public sealed class CatBreathing : MonoBehaviour
    {
        Vector3 original;void Start(){original=transform.localScale;}void Update(){transform.localScale=Vector3.Scale(original,new Vector3(1,1+Mathf.Sin(Time.time*1.3f)*.014f,1));}
    }
    public sealed class AmbientGesture : MonoBehaviour
    {
        AvatarActor actor;float next;void Start(){actor=GetComponent<AvatarActor>();next=Time.time+UnityEngine.Random.Range(4,12);}
        void Update(){if(Time.time<next)return;actor.Gesture();next=Time.time+UnityEngine.Random.Range(8,18);}
    }
}
