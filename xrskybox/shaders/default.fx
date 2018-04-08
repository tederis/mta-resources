texture tSkyTex0;
texture tSkyTex1;
float fFactor;
float3 vecColor;

//---------------------------------------------------------------------
// Include some common stuff
//---------------------------------------------------------------------
#include "mta-helper.fx" 
 
//-----------------------------------------------------------------------
//-- Sampler for the new texture
//-----------------------------------------------------------------------
samplerCUBE s_sky0 = sampler_state
{
    Texture = (tSkyTex0);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MIPMAPLODBIAS = 0.000000;
};
samplerCUBE s_sky1 = sampler_state
{
    Texture = (tSkyTex1);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MIPMAPLODBIAS = 0.000000;
};

 
//-----------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//-----------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    float3 Normal : NORMAL0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
//-----------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//-----------------------------------------------------------------------
struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float3 TexCoord : TEXCOORD0;
};


 
//--------------------------------------------------------------------------------------------
//-- VertexShaderFunction
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//--------------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    PS.Position = mul(float4(VS.Position, 1), gWorldViewProjection);
    PS.Position.w = PS.Position.z;
 
    //-- Pass through tex coord
    PS.TexCoord = VS.Normal;
  
    PS.Diffuse = VS.Diffuse;
 
    return PS;
}
 
 
//--------------------------------------------------------------------------------------------
//-- PixelShaderFunction
//--  1. Read from PS structure
//--  2. Process
//--  3. Return pixel color
//--------------------------------------------------------------------------------------------
half4 PixelShaderFunction(PSInput PS) : COLOR0
{
    half3 	s0	= texCUBE(s_sky0,PS.TexCoord);
	half3 	s1	= texCUBE(s_sky1,PS.TexCoord);
	half3	sky	= vecColor*lerp(s0,s1,fFactor)*2;

	return  half4	(sky,1);
}
 
 
//--------------------------------------------------------------------------------------------
//-- Techniques
//--------------------------------------------------------------------------------------------
technique tec
{
    pass P0
    {
        FogEnable = false;
        //DepthBias = -0.0003;
        AlphaRef = 1;
        AlphaBlendEnable = TRUE;
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}