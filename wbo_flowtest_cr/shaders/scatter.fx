//#define GENERATE_NORMALS
#include "mta-helper.fx"

texture Tex0;
texture snowTex;

sampler2D InputTexture : register(s0);

float4x4 lightView;
float4x4 lightProj;
float4x4 RotMat;

float3 lightPosition;

float3 topVector = float3(0,0,1);
float4 lightColor = float4(0,0.5f,0,0.3);
 
//---------------------------------------------------------------------
//-- Sampler for the main texture (needed for pixel shaders)
//---------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (Tex0);
};

sampler SamplerSnow = sampler_state
{
    Texture = (snowTex);
};
 
 
//---------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//---------------------------------------------------------------------
struct VSInput
{
	float3 Position : POSITION;
	float3 Normal : NORMAL0;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
//---------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//---------------------------------------------------------------------
struct PSInput
{
	float4 Position : POSITION0;
	float4 Diffuse  : COLOR0;
	float2 TexCoord : TEXCOORD0;
	float4 TexCoord1	: TEXCOORD1;
	//float3 LightVec : TEXCOORD2;
};
 
 
//-----------------------------------------------------------------------------
//-- VertexShaderExample
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//-----------------------------------------------------------------------------
PSInput VertexShaderExample(VSInput VS)
{
    PSInput PS = (PSInput)0;
 
	float4 vertex = float4(VS.Position, 1);
	
	PS.Position = mul(vertex, gWorldViewProjection);
	
	//float3 WorldNormal = MTACalcWorldNormal( VS.Normal );
	//PS.Diffuse = MTACalcGTAVehicleDiffuse( WorldNormal, VS.Diffuse );
    PS.Diffuse = VS.Diffuse;
	
	//PS.dp = dot(topVector,WorldNormal);
	
    PS.TexCoord = VS.TexCoord;
	
	PS.TexCoord1 = mul(vertex, gWorld);
	
	//PS.LightVec = PS.TexCoord1 - lightPosition;
	
	//float4x4 lightView2 = RotMat * lightView;
    PS.TexCoord1 = mul(PS.TexCoord1, lightView);
    PS.TexCoord1 = mul(PS.TexCoord1, lightProj);
 
    return PS;
}

float LightFalloff = 14.0f;
 
//-----------------------------------------------------------------------------
//-- PixelShaderExample
//--  1. Read from PS structure
//--  2. Process
//--  3. Return pixel color
//-----------------------------------------------------------------------------
float4 PixelShaderExample(PSInput PS) : COLOR0
{
    float4 finalColor = 0;//= tex2D(InputTexture, PS.TexCoord);
	//finalColor *= PS.Diffuse;	
	
	float2 TexCoords;
	TexCoords.x = PS.TexCoord1.x/PS.TexCoord1.w/2.0f + 0.5f;
    TexCoords.y = -PS.TexCoord1.y/PS.TexCoord1.w/2.0f + 0.5f;
	
	if((saturate(TexCoords.x) == TexCoords.x) && (saturate(TexCoords.y) == TexCoords.y) && PS.TexCoord1.w > 0)
	{
		//float4 finalColor2 = tex2D(Sampler0, TexCoords);
		
		//float LenSq = dot(PS.LightVec, PS.LightVec);
		//float Attn = min(( LightFalloff * LightFalloff ) / LenSq, 11.0f);
		
		//float4 I = (finalColor2 * Attn);// + Ambient;
		
		//finalColor = finalColor2;// + I;
		finalColor = lightColor;
		
		//finalColor = lerp(finalColor,finalColor2,PS.dp);
	}
 
    return finalColor;// * PS.Diffuse;
}
 
 
//-----------------------------------------------------------------------------
//-- Techniques
//-----------------------------------------------------------------------------
 
//--
//-- MTA will try this technique first:
//--
technique complercated
{
    pass P0
    {
		//AlphaBlendEnable = true; 
		//SrcBlend = One; 
		//DestBlend = One;
	
        VertexShader = compile vs_2_0 VertexShaderExample();
        PixelShader  = compile ps_2_0 PixelShaderExample();
    }
}
 
//--
//-- And if the preceding technique will not validate on
//-- the players computer, MTA will try this one:
//--
technique simple
{
    pass P0
    {
        
    }
}