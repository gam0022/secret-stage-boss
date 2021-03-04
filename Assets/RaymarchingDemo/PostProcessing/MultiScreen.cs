using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(MultiScreenRenderer), PostProcessEvent.AfterStack, "Custom/MultiScreen", false)]
public sealed class MultiScreen : PostProcessEffectSettings
{
    [Range(1f, 10f), Tooltip("分割数")]
    public FloatParameter divisionNumber = new FloatParameter { value = 3f };

    [Tooltip("グリッドごとの色相の変化速度")]
    public Vector2Parameter hueShift = new Vector2Parameter { value = new Vector2(0.1f, 0.3f) };

    [Range(0f, 1f), Tooltip("色のブレンド率")]
    public FloatParameter blend = new FloatParameter { value = 0.5f };
}

public sealed class MultiScreenRenderer : PostProcessEffectRenderer<MultiScreen>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/MultiScreen"));

        sheet.properties.SetFloat("_DivisionNumber", settings.divisionNumber);
        sheet.properties.SetVector("_HueShift", settings.hueShift);
        sheet.properties.SetFloat("_Blend", settings.blend);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}