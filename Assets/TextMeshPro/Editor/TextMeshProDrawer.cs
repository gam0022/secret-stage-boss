using UnityEditor;
using UnityEngine;
using UnityEngine.Playables;
using TMPro;

[CustomPropertyDrawer(typeof(TextMeshProBehaviour))]
public class TextMeshProDrawer : PropertyDrawer
{
    public override float GetPropertyHeight (SerializedProperty property, GUIContent label)
    {
        int fieldCount = 3;
        return fieldCount * EditorGUIUtility.singleLineHeight;
    }

    public override void OnGUI (Rect position, SerializedProperty property, GUIContent label)
    {
        SerializedProperty textProp = property.FindPropertyRelative("text");
        SerializedProperty colorProp = property.FindPropertyRelative("color");
        SerializedProperty fontSizeProp = property.FindPropertyRelative("fontSize");

        Rect singleFieldRect = new Rect(position.x, position.y, position.width, EditorGUIUtility.singleLineHeight);
        EditorGUI.PropertyField(singleFieldRect, textProp);

        singleFieldRect.y += EditorGUIUtility.singleLineHeight;
        EditorGUI.PropertyField(singleFieldRect, colorProp);

        singleFieldRect.y += EditorGUIUtility.singleLineHeight;
        EditorGUI.PropertyField(singleFieldRect, fontSizeProp);
    }
}
