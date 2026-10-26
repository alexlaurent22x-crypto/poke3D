using System;
using System.Collections.Generic;
using UnityEngine;

namespace Poks
{
    public static class ArtMaterials
    {
        [Serializable] class Entry { public string name,baseMap,normalMap,maskMap;public float[] color;public float metallic,smoothness; }
        [Serializable] class Catalog { public Entry[] materials; }
        static Dictionary<string,Material> cache;
        public static Material Make(string name,Color color,float metallic=0,float smoothness=.5f)
        {
            var shader=Shader.Find("HDRP/Lit");
            if(shader==null)throw new InvalidOperationException("HDRP/Lit absent : attendez la fin de l'import HDRP et exécutez POKS > Préparer le projet.");
            var m=new Material(shader){name=name,enableInstancing=true};m.SetColor("_BaseColor",color);m.SetFloat("_Metallic",metallic);m.SetFloat("_Smoothness",smoothness);return m;
        }
        public static Material[] BuildCatalog()
        {
            if(cache==null) {
                cache=new Dictionary<string,Material>();var file=Resources.Load<TextAsset>("ArtCatalog");
                if(file==null)throw new InvalidOperationException("ArtCatalog manquant");
                foreach(var e in JsonUtility.FromJson<Catalog>(file.text).materials) {
                    var m=Make(e.name,new Color(e.color[0],e.color[1],e.color[2],e.color[3]),e.metallic,e.smoothness);
                    if(!string.IsNullOrEmpty(e.baseMap))m.SetTexture("_BaseColorMap",Resources.Load<Texture2D>(e.baseMap));
                    if(!string.IsNullOrEmpty(e.normalMap)){m.SetTexture("_NormalMap",Resources.Load<Texture2D>(e.normalMap));m.EnableKeyword("_NORMALMAP");m.EnableKeyword("_NORMALMAP_TANGENT_SPACE");}
                    if(!string.IsNullOrEmpty(e.maskMap)){m.SetTexture("_MaskMap",Resources.Load<Texture2D>(e.maskMap));m.EnableKeyword("_MASKMAP");}
                    if(e.name.Contains("Lamp")){m.SetColor("_EmissiveColor",new Color(3.5f,1.8f,.6f));}
                    cache[e.name]=m;
                }
            }
            if(cache.TryGetValue("ChairDamask_wood",out var wood)) {
                foreach(string name in new[]{"PokerTable_Mahogany","Salon_WalnutPanels"})if(cache.TryGetValue(name,out var target)) {
                    foreach(string slot in new[]{"_BaseColorMap","_NormalMap","_MaskMap"})if(wood.GetTexture(slot)!=null)target.SetTexture(slot,wood.GetTexture(slot));
                    target.EnableKeyword("_NORMALMAP");target.EnableKeyword("_NORMALMAP_TANGENT_SPACE");target.EnableKeyword("_MASKMAP");
                }
            }
            return new List<Material>(cache.Values).ToArray();
        }
        public static void Apply(GameObject model)
        {
            BuildCatalog();
            foreach(var r in model.GetComponentsInChildren<Renderer>(true)) {
                var slots=r.sharedMaterials;
                for(int i=0;i<slots.Length;i++)if(slots[i]!=null) {
                    string key=slots[i].name.Replace(" (Instance)","");
                    if(cache.TryGetValue(key,out var m))slots[i]=m;
                }
                r.sharedMaterials=slots;
            }
        }
        public static GameObject Spawn(string name,Vector3 position,Quaternion rotation,Transform parent=null)
        {
            var prefab=Resources.Load<GameObject>("Models/"+name);
            if(prefab==null)throw new InvalidOperationException("FBX manquant : "+name);
            var go=UnityEngine.Object.Instantiate(prefab,position,rotation,parent);go.name=name;Apply(go);return go;
        }
    }
}
