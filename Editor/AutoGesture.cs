// automatically selects a gameobject when entering play mode
// in my case, GestureManager, but you can change to whatever
// public domain idc
using UnityEngine;
using UnityEditor;

[InitializeOnLoad]
public class AutoSelectGestureManager
{
    static AutoSelectGestureManager()
    {
        EditorApplication.playModeStateChanged += OnPlayModeStateChanged;
    }

    private static void OnPlayModeStateChanged(PlayModeStateChange state)
    {
        if (state == PlayModeStateChange.EnteredPlayMode)
        {
            GameObject gestureManager = GameObject.Find("GestureManager"); // can be any gameobject
            if (gestureManager != null)
            {
                Selection.activeGameObject = gestureManager;
				FocusInspectorWindow(); // can remove or modify below
            }
            else
            {
                Debug.LogWarning("GestureManager not found in the scene.");
            }
        }
    }
	
	private static void FocusInspectorWindow()
    {
        EditorApplication.delayCall += () =>
        {
            System.Type inspectorType = typeof(Editor).Assembly.GetType("UnityEditor.InspectorWindow");
            EditorWindow inspectorWindow = EditorWindow.GetWindow(inspectorType);
            inspectorWindow.Focus();
        };
    }
}