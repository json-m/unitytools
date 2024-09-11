// short helper to delete entire shader cache
// public domain idc
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

public class ClearShaderCache : MonoBehaviour 
{

	[MenuItem("Tools/Clear shader cache")]
	static public void ClearShaderCache_Command()
	{
		var shaderCachePath = Path.Combine( Application.dataPath , "../Library/ShaderCache");
		Directory.Delete( shaderCachePath , true );
	}


}