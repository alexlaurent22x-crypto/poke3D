using System;
using System.Linq;
using UnityEngine;

namespace Poks
{
    public sealed class AvatarActor : MonoBehaviour
    {
        Animation clips;
        string idle,deal;
        Transform head;
        Quaternion headRest;
        float gestureUntil;
        public void Initialize(string source)
        {
            clips=GetComponentInChildren<Animation>();
            if(clips==null)clips=gameObject.AddComponent<Animation>();
            foreach(var clip in Resources.LoadAll<AnimationClip>("Models/"+source)) {
                if(!clip.legacy||clip.name.StartsWith("__preview__")||clip.name.StartsWith("Key"))continue;
                clips.AddClip(clip,clip.name);
                if(idle==null||clip.name.ToLowerInvariant().Contains("idle"))idle=clip.name;
                if(clip.name.ToLowerInvariant().Contains("deal"))deal=clip.name;
            }
            if(idle!=null){clips[idle].wrapMode=WrapMode.Loop;clips.Play(idle);}
            head=GetComponentsInChildren<Transform>().FirstOrDefault(t=>t.name=="head");
            if(head!=null)headRest=head.localRotation;
        }
        public void Gesture(){gestureUntil=Time.time+(deal!=null?Mathf.Max(1.3f,clips[deal].length):1.3f);if(deal!=null)clips.CrossFade(deal,.2f);}
        void Update(){if(gestureUntil>0&&Time.time>gestureUntil){gestureUntil=0;if(idle!=null)clips.CrossFade(idle,.3f);}}
        public void Configure(AvatarProfile p)
        {
            foreach(var r in GetComponentsInChildren<SkinnedMeshRenderer>(true)) {
                string[] names={"Build","Eyes","Nose","Mouth","Jaw","Face"};float[] values={p.build,p.eyes,p.nose,p.mouth,p.jaw,p.face};
                for(int i=0;i<names.Length;i++){int index=r.sharedMesh.GetBlendShapeIndex(names[i]);if(index<0)for(int k=0;k<r.sharedMesh.blendShapeCount;k++)if(r.sharedMesh.GetBlendShapeName(k).EndsWith("."+names[i])){index=k;break;}if(index>=0)r.SetBlendShapeWeight(index,values[i]*100);}
            }
            foreach(var t in GetComponentsInChildren<Transform>(true)) {
                if(t.name.StartsWith("HairOption"))t.gameObject.SetActive(t.name=="HairOption"+p.hair&&p.hair!=0);
                else if(t.name.StartsWith("BeardOption"))t.gameObject.SetActive(!p.female&&t.name=="BeardOption"+p.beard&&p.beard!=0);
                else if(IsOriginalHair(t.name))t.gameObject.SetActive(false);
            }
            foreach(var r in GetComponentsInChildren<Renderer>(true)) {
                var mats=r.materials;
                foreach(var m in mats)if(m.name.IndexOf("eveningwear",StringComparison.OrdinalIgnoreCase)>=0||m.name.Contains("wool")||m.name.Contains("garment"))
                    m.SetColor("_BaseColor",p.outfit==0?new Color(.10f,.15f,.18f):new Color(.025f,.018f,.03f));
            }
        }
        static bool IsOriginalHair(string n)=>n.IndexOf("hair",StringComparison.OrdinalIgnoreCase)>=0||n.StartsWith("Scalp")||n.StartsWith("Swept")||n.StartsWith("Bun");
        public void TintOutfit(Color color)
        {
            foreach(var r in GetComponentsInChildren<Renderer>(true))foreach(var m in r.materials)
                if(m.name.Contains("wool")||m.name.Contains("eveningwear"))m.SetColor("_BaseColor",color);
        }
    }
}
