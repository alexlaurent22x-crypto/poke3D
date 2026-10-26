using UnityEngine;
using UnityEngine.EventSystems;

namespace Poks
{
    public sealed class SeatedOrbitCamera : MonoBehaviour
    {
        public Vector3 target=new Vector3(0,1.05f,-.35f);
        public float distance=3.25f;
        float yaw=180,pitch=23;
        bool play,drag;
        public void SetPlay(bool value)
        {
            Release();play=value;yaw=180;pitch=23;
            if(!play){transform.position=new Vector3(3.7f,2.2f,-4.8f);transform.LookAt(new Vector3(0,1,0));}
        }
        public void Portrait(){play=false;Release();transform.position=new Vector3(1.1f,1.55f,-.55f);transform.LookAt(new Vector3(0,1.22f,-1.62f));}
        void Release(){drag=false;Cursor.lockState=CursorLockMode.None;Cursor.visible=true;}
        void OnDisable()=>Release();
        void OnApplicationFocus(bool focused){if(!focused)Release();}
        void LateUpdate()
        {
            if(!play)return;
            if(Input.GetKeyDown(KeyCode.Escape)){Release();yaw=180;pitch=23;distance=3.25f;}
            if(Input.GetMouseButtonDown(0)&&(EventSystem.current==null||!EventSystem.current.IsPointerOverGameObject())) {
                drag=true;Cursor.lockState=CursorLockMode.Locked;Cursor.visible=false;
            }
            if(Input.GetMouseButtonUp(0)||!Input.GetMouseButton(0))Release();
            if(drag){yaw+=Input.GetAxisRaw("Mouse X")*3f;pitch=Mathf.Clamp(pitch-Input.GetAxisRaw("Mouse Y")*2.3f,-5,58);}
            if(EventSystem.current==null||!EventSystem.current.IsPointerOverGameObject())distance=Mathf.Clamp(distance-Input.mouseScrollDelta.y*.15f,2.4f,4.1f);
            var rotation=Quaternion.Euler(-pitch,yaw,0);
            // The player sits on -Z; yaw 180 places the default view behind that seat.
            transform.position=target+rotation*new Vector3(0,0,distance);
            transform.LookAt(target);
        }
    }
}
