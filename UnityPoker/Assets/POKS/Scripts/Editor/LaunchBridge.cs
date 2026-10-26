using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;

namespace Poks.Editor
{
    // A request file also reaches an already-open editor, without opening a second Unity instance.
    [InitializeOnLoad]
    public static class LaunchBridge
    {
        const string StageKey="POKS.Launch.Stage";
        static double nextPoll;
        static LaunchBridge(){EditorApplication.update+=Poll;}
        public static void StartGame(){SessionState.SetInt(StageKey,1);}
        static void Poll()
        {
            if(EditorApplication.timeSinceStartup<nextPoll)return;
            nextPoll=EditorApplication.timeSinceStartup+.5;
            if(EditorApplication.isCompiling||EditorApplication.isUpdating)return;
            string request=Path.GetFullPath(Path.Combine(Application.dataPath,"../POKS-LAUNCH.request"));
            if(File.Exists(request)) {
                try{File.Delete(request);}catch(Exception e){Debug.LogWarning("POKS lanceur : "+e.Message);return;}
                if(!EditorApplication.isPlaying)SessionState.SetInt(StageKey,1);
            }
            int stage=SessionState.GetInt(StageKey,0);
            if(stage==0||EditorApplication.isPlaying)return;
            try {
                if(stage==1) {
                    SessionState.SetInt(StageKey,2);
                    if(GraphicsSettings.defaultRenderPipeline==null)ProjectSetup.Prepare();
                    // Never overwrite an unsaved editor scene in response to the launcher.
                    if(UnityEngine.SceneManagement.SceneManager.GetActiveScene().isDirty) {
                        SessionState.SetInt(StageKey,0);
                        EditorUtility.DisplayDialog("POKS","Une scène contient des modifications non enregistrées. Enregistrez-la, puis relancez le raccourci.","OK");return;
                    }
                    EditorSceneManager.OpenScene("Assets/POKS/Scenes/Salon.unity");
                    return;
                }
                SessionState.SetInt(StageKey,0);
                EditorApplication.ExecuteMenuItem("Window/General/Game");
                EditorApplication.isPlaying=true;
            }catch(Exception e){SessionState.SetInt(StageKey,0);Debug.LogException(e);}
        }
    }
}
