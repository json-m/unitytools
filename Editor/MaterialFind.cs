// returns a clickable list of all gameobjects in the scene with materials associated with them
// also displays the shader if one is applied
// public domain idc
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

public class FindObjectsWithMaterials : EditorWindow
{
    private Vector2 scrollPosition;
    private List<GameObject> objectsWithMaterials = new List<GameObject>();
    private float objectColumnWidth = 200f;
    private float materialColumnWidth = 200f;

    [MenuItem("Tools/Find Objects With Materials")]
    public static void ShowWindow()
    {
        GetWindow<FindObjectsWithMaterials>("Objects With Materials");
    }

    void OnGUI()
    {
        if (GUILayout.Button("Find Objects With Materials"))
        {
            FindObjects();
        }

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Object", EditorStyles.boldLabel, GUILayout.Width(objectColumnWidth));
        EditorGUILayout.LabelField("Material", EditorStyles.boldLabel, GUILayout.Width(materialColumnWidth));
        EditorGUILayout.LabelField("Shader", EditorStyles.boldLabel);
        EditorGUILayout.EndHorizontal();

        scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition);

        foreach (GameObject obj in objectsWithMaterials)
        {
            if (obj != null)
            {
                Renderer renderer = obj.GetComponent<Renderer>();
                if (renderer != null && renderer.sharedMaterial != null)
                {
                    EditorGUILayout.BeginHorizontal();
                    EditorGUILayout.ObjectField(obj, typeof(GameObject), true, GUILayout.Width(objectColumnWidth));
                    EditorGUILayout.LabelField(renderer.sharedMaterial.name, GUILayout.Width(materialColumnWidth));
                    EditorGUILayout.LabelField(renderer.sharedMaterial.shader.name);
                    EditorGUILayout.EndHorizontal();
                }
            }
        }

        EditorGUILayout.EndScrollView();
    }

    void FindObjects()
    {
        GameObject[] allObjects = FindObjectsOfType<GameObject>();
        objectsWithMaterials.Clear();

        foreach (GameObject obj in allObjects)
        {
            Renderer renderer = obj.GetComponent<Renderer>();
            if (renderer != null && renderer.sharedMaterial != null)
            {
                objectsWithMaterials.Add(obj);
            }
        }

        Repaint();
    }
}