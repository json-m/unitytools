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
            GameObject gestureManager = GameObject.Find("GestureManager");
            if (gestureManager != null)
            {
                Selection.activeGameObject = gestureManager;
            }
            else
            {
                Debug.LogWarning("GestureManager not found in the scene.");
            }
        }
    }
}