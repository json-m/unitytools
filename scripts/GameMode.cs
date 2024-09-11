// adds a button in scene view when play mode is enabled
// click to return to game view with whatever gameobject selected
// public domain idc
using UnityEngine;
using UnityEditor;

[InitializeOnLoad]
public static class SceneViewButton
{
    private static bool wasPlayingLastFrame;

    static SceneViewButton()
    {
        SceneView.duringSceneGui += OnSceneGUI;
        EditorApplication.update += OnEditorUpdate;
    }

    static void OnEditorUpdate()
    {
        if (wasPlayingLastFrame != EditorApplication.isPlaying)
        {
            wasPlayingLastFrame = EditorApplication.isPlaying;
            SceneView.RepaintAll();
        }
    }

    static void OnSceneGUI(SceneView sceneView)
    {
        if (!EditorApplication.isPlaying)
            return;

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