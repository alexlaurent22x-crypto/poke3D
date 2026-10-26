using System;
using System.IO;
using UnityEngine;

namespace Poks
{
    [Serializable] public sealed class AvatarProfile
    {
        public int version=1;
        public bool female;
        public int outfit=1, hair=1, beard;
        public float build=.5f, eyes=.5f, nose=.5f, mouth=.5f, jaw=.5f, face=.5f;
        public string firstName="Alex", lastName="Laurent", nickname="Le Prétendant", country="France";
        public string DisplayName => string.IsNullOrWhiteSpace(nickname)?firstName+" "+lastName:nickname;
        public void Normalize()
        {
            firstName=Clean(firstName,32);lastName=Clean(lastName,32);nickname=Clean(nickname,32);country=Clean(country,48);
            outfit=Mathf.Clamp(outfit,0,1);hair=Mathf.Clamp(hair,0,4);beard=female?0:Mathf.Clamp(beard,0,2);
            build=Mathf.Clamp01(build);eyes=Mathf.Clamp01(eyes);nose=Mathf.Clamp01(nose);mouth=Mathf.Clamp01(mouth);jaw=Mathf.Clamp01(jaw);face=Mathf.Clamp01(face);
        }
        static string Clean(string s,int max){s=(s??"").Trim().Replace("\n"," ").Replace("\r"," ");return s.Substring(0,Math.Min(max,s.Length));}
        public static string FilePath=>Path.Combine(Application.persistentDataPath,"avatar.json");
        public static AvatarProfile Load()
        {
            try{if(File.Exists(FilePath)){var p=JsonUtility.FromJson<AvatarProfile>(File.ReadAllText(FilePath));if(p!=null){p.Normalize();return p;}}}
            catch(Exception e){Debug.LogWarning("Profil illisible : "+e.Message);}
            return new AvatarProfile();
        }
        public void Save()
        {
            Normalize();Directory.CreateDirectory(Application.persistentDataPath);
            string tmp=FilePath+".tmp";File.WriteAllText(tmp,JsonUtility.ToJson(this,true));
            if(File.Exists(FilePath))File.Copy(FilePath,FilePath+".backup",true);
            File.Copy(tmp,FilePath,true);File.Delete(tmp);
        }
    }
    [Serializable] public sealed class Membership
    {
        public AvatarProfile identity;
        public string number,qualifiedAtUtc;
        public string eventName="Qualification · Le Salon des Prétendants";
        public string status="QUALIFIÉ — FUTUR GRAND POKS CASINO 3D";
    }
}
