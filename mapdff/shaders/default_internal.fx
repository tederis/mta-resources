bool UseNormals;

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
sampler SamplerLMap = sampler_state
{
    Texture = (gTexture1);
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
};

float3 	v_sun 		(float3 n)		{
    return L_sun_color*0.6f;
}

/*float3	p_hemi		(float2 tc) 	{
	//half3	t_lmh 	= tex2D		(s_hemi, tc);
	//return  dot	(t_lmh,1.h/3.h);
	float4	t_lmh 	= tex2D		(s_hemi, tc);
	return  t_lmh.a;
}*/
 
 
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
 
    PS.Diffuse = float4(0,0,0,0);
    
    //PS.c1 = v_sun(-VS.Normal);
 
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
	float4	t_lmap 	= tex2D		(SamplerLMap,PS.TexCoord2);
    
	// lighting
	float3 	l_base 	= 0;				// base light-map
    
	//Point lights
	for(int i = 0; i < 5; i++)
	{	
		float3 Light = PointLightPosition[i] - PS.WorldPos;
		float Attenuation = saturate(1.0f - length(Light) / 5.0f);
		float Lambert = 0.35;
		
		l_base += Lambert * Attenuation * PointLightColor[i];
	}
    
    float Cutoff = 0;
    
	//Spotlights
	/*for(int i = 0; i < 5; i++)
	{
		float3 Light = (SpotLightPosition[i] - PS.WorldPos) * 0.04;
		float Attenuation = saturate(1.0 - dot(Light, Light));
		float SpotCone = pow(saturate(dot(normalize(Light), normalize(SpotLightDirection[i]))), SpotLightConeAngle) * 5;
 
		l_base += SpotCone * Attenuation * SpotLightColor;
	}*/
    
	float3	l_hemi 	= L_hemi_color*t_lmap.r;
	float3 	l_sun 	= (L_sun_color)*t_lmap.b;
	float3	light	= L_ambient + l_base + l_sun + l_hemi;

	// final-color
	float3	final 	= light*t_base*2;
 
    return float4(final.rgb, 1);
    //float val = t_lmap.b;
    //return float4(val, val, val,1);
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