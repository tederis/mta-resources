#include "mta-helper.fx"
 
float3 InternalPos[4];
float2 InternalSize[4];
float3 InternalNormal[4];
float4 InternalColor[4];

static float3 UP = {0, 0, 1};
 
texture Tex0;
sampler Sampler0 = sampler_state
{
    Texture = (Tex0);
};

struct VSInput
{
    float3 Position : POSITION;
    float3 Normal : NORMAL;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
struct PSInput
{
  float4 Position : POSITION0;
  float4 Diffuse  : COLOR0;
  float2 TexCoord : TEXCOORD0;
};
 
PSInput VertexShaderExample(VSInput VS)
{
    PSInput PS = (PSInput)0;
 
    int index = floor ( VS.Normal.x + 0.5f );
    
    // Поворачиваем квадрат по нормали
    float3 normal = normalize(InternalNormal[index]);
    float3 right = normalize(cross(normal, UP));
    float3 up = normalize(cross(normal, right));
   
    float3 outPos;
    float2 size = InternalSize[index]*VS.Position.xy;
    outPos.x = (right.x*size.x) + (up.x*size.y);
    outPos.y = (right.y*size.x) + (up.y*size.y);
    outPos.z =                    (up.z*size.y);
    
    // Применяем смещение
    float3 objPos = float3(gWorld._m30, gWorld._m31, gWorld._m32);
    outPos += InternalPos[index] - objPos;
 
    PS.Position = MTACalcScreenPosition ( outPos );
	
    PS.Diffuse = InternalColor[index];
    /*if (VS.Normal.x == 0)
    {
        PS.Diffuse = float4(1, 0, 0, 1);
    }*/
	
	PS.TexCoord = VS.TexCoord;
 
    return PS;
}
 
float4 PixelShaderExample(PSInput PS) : COLOR0
{
    float4 texel = tex2D(Sampler0, PS.TexCoord);
	
	float4 finalColor = texel * PS.Diffuse;

	return finalColor;
} 

technique complercated
{
    pass P0
    {
        AlphaTestEnable = false;
        AlphaBlendEnable = true;
        SrcBlend = SrcAlpha; 
        DestBlend = InvSrcAlpha;
        ZWriteEnable = FALSE;
        
        
        VertexShader = compile vs_2_0 VertexShaderExample();
        PixelShader  = compile ps_2_0 PixelShaderExample();
    }
}