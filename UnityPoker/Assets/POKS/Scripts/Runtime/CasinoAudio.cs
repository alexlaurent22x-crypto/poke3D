using System.Collections;
using UnityEngine;

namespace Poks
{
    public sealed class CasinoAudio : MonoBehaviour
    {
        AudioSource foley,music,bar,voice;
        public bool Muted {get;private set;}
        void Awake()
        {
            foley=gameObject.AddComponent<AudioSource>();foley.volume=.38f;
            music=gameObject.AddComponent<AudioSource>();music.clip=Resources.Load<AudioClip>("Audio/lounge_original");music.loop=true;music.volume=.18f;if(music.clip!=null)music.Play();
            bar=gameObject.AddComponent<AudioSource>();bar.volume=.07f;voice=gameObject.AddComponent<AudioSource>();voice.volume=.8f;
            StartCoroutine(BarLoop());
        }
        IEnumerator BarLoop(){while(true){yield return new WaitForSeconds(Random.Range(12,24));if(!Muted)bar.PlayOneShot(Resources.Load<AudioClip>("Audio/bar"));}}
        public void Play(string name){if(Muted)return;var clip=Resources.Load<AudioClip>("Audio/"+name);if(clip!=null)foley.PlayOneShot(clip);}
        public void Speak(string cue){if(Muted)return;var clip=Resources.Load<AudioClip>("Audio/Voice/"+cue);if(clip!=null){voice.Stop();voice.PlayOneShot(clip);}}
        public void Toggle(){Muted=!Muted;foreach(var s in GetComponents<AudioSource>())s.mute=Muted;}
    }
}
