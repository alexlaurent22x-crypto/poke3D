using System;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;

namespace Poks.Editor
{
    [InitializeOnLoad]
    public static class ProjectSetup
    {
        const string PipelinePath="Assets/POKS/Settings/POKS-HDRP.asset";
        const string ScenePath="Assets/POKS/Scenes/Salon.unity";
        static ProjectSetup(){EditorApplication.delayCall+=FirstImport;}
        static void FirstImport()
        {
            if(EditorApplication.isCompiling||EditorApplication.isUpdating){EditorApplication.delayCall+=FirstImport;return;}
            if(Application.isBatchMode)return;
            if(AssetDatabase.LoadAssetAtPath<HDRenderPipelineAsset>(PipelinePath)==null) {
                try{Prepare();}
                catch(Exception e){Debug.LogException(e);Debug.LogError("POKS : initialisation à terminer avec le menu POKS > Préparer le projet.");}
            }
        }
        [MenuItem("POKS/Préparer le projet")]
        public static void Prepare()
        {
            Directory.CreateDirectory("Assets/POKS/Settings");AssetDatabase.Refresh();
            PlayerSettings.companyName="POKS";PlayerSettings.productName="POKS CASINO 3D — LE TOURNOI";
            PlayerSettings.colorSpace=ColorSpace.Linear;
            PlayerSettings.defaultScreenWidth=1280;PlayerSettings.defaultScreenHeight=800;
            PlayerSettings.resizableWindow=true;PlayerSettings.fullScreenMode=FullScreenMode.Windowed;
            PlayerSettings.runInBackground=false;
            PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.StandaloneWindows64,false);
            PlayerSettings.SetGraphicsAPIs(BuildTarget.StandaloneWindows64,new[]{GraphicsDeviceType.Direct3D11,GraphicsDeviceType.Direct3D12});
            // This prototype uses Unity's built-in mouse/keyboard API and StandaloneInputModule.
            var settings=new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset"));
            var input=settings.FindProperty("activeInputHandler");if(input!=null){input.intValue=0;settings.ApplyModifiedPropertiesWithoutUndo();}
            var asset=AssetDatabase.LoadAssetAtPath<HDRenderPipelineAsset>(PipelinePath);
            if(asset==null){asset=ScriptableObject.CreateInstance<HDRenderPipelineAsset>();asset.name="POKS — RTX 2070";AssetDatabase.CreateAsset(asset,PipelinePath);}
            var render=asset.currentPlatformRenderPipelineSettings;render.supportRayTracing=false;asset.currentPlatformRenderPipelineSettings=render;
            GraphicsSettings.defaultRenderPipeline=asset;QualitySettings.renderPipeline=asset;
            // HDRP 17 owns resource initialization; invoke its version-pinned editor initializer.
            // HDRenderPipelineAsset.Reset also invokes this method. Reflection avoids a dependency on an internal type.
            var type=typeof(HDRenderPipelineAsset).Assembly.GetType("UnityEngine.Rendering.HighDefinition.HDRenderPipelineGlobalSettings");
            var ensure=type?.GetMethod("Ensure",BindingFlags.Static|BindingFlags.NonPublic);
            if(ensure==null)throw new InvalidOperationException("Initialiseur HDRP 17 introuvable. Utilisez Window > Rendering > HDRP Wizard.");
            ensure.Invoke(null,new object[]{true});
            if(!AssetDatabase.IsValidFolder("Assets/POKS/Resources/Materials"))AssetDatabase.CreateFolder("Assets/POKS/Resources","Materials");
            foreach(var material in ArtMaterials.BuildCatalog()) {
                string path="Assets/POKS/Resources/Materials/"+material.name+".mat";
                var existing=AssetDatabase.LoadAssetAtPath<Material>(path);
                if(existing==null)AssetDatabase.CreateAsset(new Material(material),path);
                else {EditorUtility.CopySerialized(material,existing);EditorUtility.SetDirty(existing);}
            }
            EditorUtility.SetDirty(asset);
            EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(ScenePath,true)};
            AssetDatabase.SaveAssets();
            if(!Application.isBatchMode&&!UnityEngine.SceneManagement.SceneManager.GetActiveScene().isDirty)EditorSceneManager.OpenScene(ScenePath);
            Debug.Log("POKS : paramètres HDRP et Windows configurés. Ouvrez Salon.unity et appuyez sur Play. Ceci n'est pas une validation du rendu.");
        }
        [MenuItem("POKS/Ouvrir le Salon")]
        public static void OpenSalon(){if(EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())EditorSceneManager.OpenScene(ScenePath);}
        [MenuItem("POKS/Construire Windows x64")]
        public static void BuildWindows()
        {
            Prepare();Directory.CreateDirectory("Build/Windows");
            var report=BuildPipeline.BuildPlayer(new BuildPlayerOptions{scenes=new[]{ScenePath},locationPathName="Build/Windows/POKS-Casino-3D.exe",target=BuildTarget.StandaloneWindows64,options=BuildOptions.None});
            if(report.summary.result!=UnityEditor.Build.Reporting.BuildResult.Succeeded)throw new Exception("Export Windows échoué : "+report.summary.result);
            Directory.CreateDirectory("Build/Windows/Licenses");
            foreach(string file in Directory.GetFiles("Assets/POKS/Licenses"))if(!file.EndsWith(".meta"))File.Copy(file,Path.Combine("Build/Windows/Licenses",Path.GetFileName(file)),true);
            File.Copy("Documentation/ASSETS.md","Build/Windows/CREDITS.md",true);
            Debug.Log("Build Windows créé : distribuez tout le dossier Build/Windows, crédits compris.");
        }
    }
    public sealed class PoksAssetImporter : AssetPostprocessor
    {
        void OnPreprocessModel()
        {
            if(!assetPath.StartsWith("Assets/POKS/Resources/Models/"))return;
            var importer=(ModelImporter)assetImporter;importer.importCameras=false;importer.importLights=false;
            importer.importBlendShapes=true;importer.importNormals=ModelImporterNormals.Import;
            importer.animationType=ModelImporterAnimationType.Legacy;importer.importAnimation=true;
            importer.materialImportMode=ModelImporterMaterialImportMode.ImportStandard;
            importer.generateSecondaryUV=false;importer.isReadable=false;
        }
        void OnPreprocessAnimation()
        {
            if(!assetPath.StartsWith("Assets/POKS/Resources/Models/"))return;
            var importer=(ModelImporter)assetImporter;var clips=importer.defaultClipAnimations;
            foreach(var clip in clips){clip.loopTime=clip.name.ToLowerInvariant().Contains("idle");clip.wrapMode=clip.loopTime?WrapMode.Loop:WrapMode.Once;}
            importer.clipAnimations=clips;
        }
        void OnPreprocessTexture()
        {
            if(!assetPath.StartsWith("Assets/POKS/Resources/"))return;
            var importer=(TextureImporter)assetImporter;importer.maxTextureSize=2048;importer.mipmapEnabled=true;
            if(assetPath.Contains("normalMap")){importer.textureType=TextureImporterType.NormalMap;importer.sRGBTexture=false;}
            if(assetPath.Contains("maskMap"))importer.sRGBTexture=false;
            if(assetPath.Contains("/Cards/")){importer.wrapMode=TextureWrapMode.Clamp;importer.maxTextureSize=1024;}
        }
        void OnPreprocessAudio()
        {
            if(!assetPath.StartsWith("Assets/POKS/Resources/Audio/"))return;
            var importer=(AudioImporter)assetImporter;var settings=importer.defaultSampleSettings;
            settings.compressionFormat=AudioCompressionFormat.Vorbis;settings.quality=.75f;
            settings.loadType=assetPath.Contains("lounge")?AudioClipLoadType.Streaming:AudioClipLoadType.DecompressOnLoad;
            importer.defaultSampleSettings=settings;importer.forceToMono=true;
        }
    }
}
