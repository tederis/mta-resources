float4 L_hemi_color = float4(0.50f,	0.50f,	0.50f, 1.0f);
float3 L_sun_color = float3(1.000f,  0.6f,  0.3f);
float3 L_sun_dir_w = float3(-0.3395f, -0.4226f, -0.8403f);
float3 L_ambient = float3(0.071f,   0.07f,  	0.079f);

//Point lights
float3 PointLightPosition[5];
float3 PointLightColor[5];

//Spotlights
float3 SpotLightPosition[5];
float3 SpotLightDirection[5];
float3 SpotLightColor = float3(0.976, 1, 0.721);
float c = 80.0f;

#define CHECK_VALUE 0.3333333333333333f

texture TexHemi1;
texture TexHemi2;
texture TexHemi3;
texture TexHemi4;
texture TexHemi5;

//---------------------------------------------------------------------
// Include some common stuff
//---------------------------------------------------------------------
#include "mta-helper.fx" 
 
//-----------------------------------------------------------------------
//-- Sampler for the new texture
//-----------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};
sampler SamplerHemi1 = sampler_state
{
    Texture = (TexHemi1);
    MipFilter = Linear;
    MinFilter = Anisotropic;
};
sampler SamplerHemi2 = sampler_state
{
    Texture = (TexHemi2);
    MipFilter = Linear;
    MinFilter = Anisotropic;
};
sampler SamplerHemi3 = sampler_state
{
    Texture = (TexHemi3);
    MipFilter = Linear;
    MinFilter = Anisotropic;
};
sampler SamplerHemi4 = sampler_state
{
    Texture = (TexHemi4);
    MipFilter = Linear;
    MinFilter = Anisotropic;
};
sampler SamplerHemi5 = sampler_state
{
    Texture = (TexHemi5);
    MipFilter = Linear;
    MinFilter = Anisotropic;
};

 
//-----------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//-----------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    //float3 Normal : NORMAL0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float2 TexCoord2 : TEXCOORD1;
};
 
//-----------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//-----------------------------------------------------------------------
struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float2 TexCoord2 : TEXCOORD1;
    float3 WorldPos : TEXCOORD3;
    //float3 c1	: COLOR1;
    //int index : TEXCOORD3;
};

float3 	v_sun 		(float3 n)		{
    return L_sun_color*0.6f;
}
 
//--------------------------------------------------------------------------------------------
//-- VertexShaderFunction
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//--------------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
    
    //MTAFixUpNormal( VS.Normal );
 
    //-- Calculate screen pos of vertex
    PS.Position = mul(float4(VS.Position, 1), gWorldViewProjection);
    
    PS.WorldPos = mul(float4(VS.Position, 1), gWorld);
 
    //-- Pass through tex coord
    PS.TexCoord = VS.TexCoord;
    PS.TexCoord2 = VS.TexCoord2;
 
    //PS.Diffuse = float4(0,0,0,0);
    
    //PS.c1 = L_sun_color*0.4f;
 
    return PS;
}
 
 
//--------------------------------------------------------------------------------------------
//-- PixelShaderFunction
//--  1. Read from PS structure
//--  2. Process
//--  3. Return pixel color
//--------------------------------------------------------------------------------------------
float4 PixelShaderFunction(PSInput PS) : COLOR0
{
    float4	t_base 	= tex2D		(Sampler0,PS.TexCoord);
    float4	t_hemi 	= 0;
    
    if (PS.TexCoord2.x == .0f && PS.TexCoord2.y == 1.0f)
    {
        // Нет лайтмапы
        float3	final 	= t_base * (L_ambient +  L_hemi_color*0.2f + L_sun_color*0.3f) * 2;
        return float4(final, t_base.a);
    }
    
    int column = floor(PS.TexCoord2.x/CHECK_VALUE);
    int row = floor(PS.TexCoord2.y/CHECK_VALUE);
    
    float2 texCoords = (PS.TexCoord2 - float2(column, row)*CHECK_VALUE) / CHECK_VALUE;
     
    int index = row * 3 + column;
    if (index == 0)
    {
        t_hemi 	= tex2D		(SamplerHemi1,texCoords);
    }
    else if (index == 1)
    {
        t_hemi 	= tex2D		(SamplerHemi2,texCoords);
    }
    else if (index == 2)
    {
        t_hemi 	= tex2D		(SamplerHemi3,texCoords);
    }
    else if (index == 3)
    {
        t_hemi 	= tex2D		(SamplerHemi4,texCoords);
    }
    else if (index == 4)
    {
        t_hemi 	= tex2D		(SamplerHemi5,texCoords);
    }
    
    float3 l_base = 0;
    
    //Point lights
	for(int i = 0; i < 3; i++)
	{	
		float3 Light = PointLightPosition[i] - PS.WorldPos;
		float Attenuation = saturate(1.0f - length(Light) / 5.0f);
		
		l_base += 0.35f * Attenuation * PointLightColor[i];
	}
    
	float3	l_hemi 	= L_hemi_color*dot	(t_hemi.rgb,CHECK_VALUE);
	float3 	l_sun 	= L_sun_color*L_sun_color*t_hemi.a;
	float3	light	= L_ambient + l_base + l_sun + l_hemi;

	// final-color
	float3	final 	= light*t_base*2;
 
    return float4(final.rgb, t_base.a);
}
 
 
//--------------------------------------------------------------------------------------------
//-- Techniques
//--------------------------------------------------------------------------------------------
technique tec
{
    pass P0
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}