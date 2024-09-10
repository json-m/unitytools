using UnityEngine;
using UnityEditor;

public static class SceneViewButton
{
    [InitializeOnLoadMethod]
    static void RegisterCallback()
    {
        SceneView.duringSceneGui += OnSceneGUI;
    }

    static void OnSceneGUI(SceneView sceneView)
    {
        Handles.BeginGUI();
        
        Rect sceneViewRect = sceneView.position;
        
        float buttonWidth = 150;
        float buttonHeight = 40;
        float padding = 40;
        
        Rect buttonRect = new Rect(
            padding, 
            sceneViewRect.height - buttonHeight - padding, 
            buttonWidth, 
            buttonHeight
        );

        if (GUI.Button(buttonRect, "Set Game View"))
        {
            SelectGameObjectAndSetView();
        }
        
        Handles.EndGUI();
    }

    static void SelectGameObjectAndSetView()
    {
        GameObject targetObject = GameObject.Find("GestureManager");
        if (targetObject != null)
        {
            Selection.activeGameObject = targetObject;
        }

        System.Type gameViewType = System.Type.GetType("UnityEditor.GameView,UnityEditor");
        if (gameViewType != null)
        {
            EditorWindow.GetWindow(gameViewType).Focus();
        }
    }
}
