//-----------------------------------------------------------------------
//-- Settings
//-----------------------------------------------------------------------
texture TexLMap;   //-- Replacement texture
texture TexBase;   //-- Replacement texture
texture TexDet;
texture TexNormal;

texture Tex1;
texture Tex2;
texture Tex3;
texture Tex4;
/*texture Tex5;
texture Tex6;
texture Tex7;
texture Tex8;
texture Tex9;*/

float4 L_hemi_color = float4(0.50f,	0.50f,	0.50f, 1.0f);
float3 L_sun_color = float3(1.000f,  0.6f,  0.3f);
float3 L_sun_dir_w = float3(-0.3395f, -0.4226f, -0.8403f);
float3 L_ambient = float3(0.071f,   0.07f,  	0.079f);

float fakeShadow = 0.498f;

//---------------------------------------------------------------------
// Include some common stuff
//---------------------------------------------------------------------
#define GENERATE_NORMALS
#include "mta-helper.fx"

 
//-----------------------------------------------------------------------
//-- Sampler for the new texture
//-----------------------------------------------------------------------
sampler Sampler1 = sampler_state
{
    Texture = (Tex1);
};
sampler Sampler2 = sampler_state
{
    Texture = (Tex2);
};
sampler Sampler3 = sampler_state
{
    Texture = (Tex3);
};
sampler Sampler4 = sampler_state
{
    Texture = (Tex4);
};

/*sampler Sampler5 = sampler_state
{
    Texture = (Tex5);
     MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
};
sampler Sampler6 = sampler_state
{
    Texture = (Tex6);
     MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
};
sampler Sampler7 = sampler_state
{
    Texture = (Tex7);
     MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
};
sampler Sampler8 = sampler_state
{
    Texture = (Tex8);
     MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MaxAnisotropy = 2;  
};
sampler Sampler9 = sampler_state
{
    Texture = (Tex9);
};*/
sampler SamplerLMap = sampler_state
{
    Texture = (TexLMap);
 
};
sampler SamplerBase = sampler_state
{
    Texture = (TexBase);

}; 
sampler SamplerNrm = sampler_state
{
    Texture = (TexNormal);

};
sampler SamplerDet = sampler_state
{
    Texture = (TexDet);
  
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
    float2 TexCoord : TEXCOORD0;
    float2 TexCoord2 : TEXCOORD1;
    float4 c0	: TEXCOORD2;
    float4 c1	: COLOR1;
};

//float3 	v_sun 		(float3 n)		{	return L_sun_color*max(0,dot(n,-L_sun_dir_w));		}
float2 	calc_detail 	(float3 w_pos)	{ 
	float  	dtl	= distance(w_pos,gCameraPosition)*0;
		dtl	= min(dtl*dtl, 1);
	float  	dt_mul	= 1  - dtl;	// dt*  [1 ..  0 ]
	float  	dt_add	= .5 * dtl;	// dt+	[0 .. 0.5]
	return	float2	(dt_mul,dt_add);
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
    
    MTAFixUpNormal( VS.Normal );
 
    float2 	dt 	= calc_detail		(VS.Position);
 
    //-- Calculate screen pos of vertex
    PS.Position = mul(float4(VS.Position, 1), gWorldViewProjection);
 
    //-- Pass through tex coord
    PS.TexCoord = VS.TexCoord;
    PS.TexCoord2 = VS.TexCoord;
 
    //-- Calculate GTA lighting for buildings
    PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );
    //--
    //-- NOTE: The above line is for GTA buildings.
    //-- If you are replacing a vehicle texture, do this instead:
    //--
    //--      // Calculate GTA lighting for vehicles
    //--      float3 WorldNormal = MTACalcWorldNormal( VS.Normal );
    //--      PS.Diffuse = MTACalcGTAVehicleDiffuse( WorldNormal, VS.Diffuse );
    
    PS.c0		= float4 		(L_hemi_color.rgb,dt.x);		// c0=hemi+v-lights, 	c0.a = dt*
	PS.c1 		= float4 		(L_sun_color*0.5f,dt.y);		// c1=sun, 		c1.a = dt+
 
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
    float4	t_base 	= tex2D		(SamplerBase,PS.TexCoord);
	float4	t_lmap 	= tex2D		(SamplerLMap,PS.TexCoord);

    float4	t_nrm 	= tex2D(SamplerNrm, PS.TexCoord);
    float3 normal = t_nrm.xzy * 2 + float3(-1, -1, -1);

    // lighting
	float3 	l_base 	= PS.c0*t_lmap.rgb;//t_lmap.rgb;				// base light-map
	float3	l_hemi 	= PS.c0*t_lmap.r;			// hemi
	float3 	l_sun 	= PS.c1*fakeShadow;//*t_lmap.a;			// sun color
	float3	light	= L_ambient + l_base + l_sun;

	// calc D-texture
	float4	t_dt 	= tex2D(SamplerDet, PS.TexCoord);

    float4 texel1 = tex2D(Sampler1, PS.TexCoord * 250);
    float4 texel2 = tex2D(Sampler2, PS.TexCoord * 250);
    float4 texel3 = tex2D(Sampler3, PS.TexCoord * 250);
    float4 texel4 = tex2D(Sampler4, PS.TexCoord * 250);
    /*float4 texel5 = tex2D(Sampler5, PS.TexCoord * 150);
    float4 texel6 = tex2D(Sampler6, PS.TexCoord * 150);
    float4 texel7 = tex2D(Sampler7, PS.TexCoord * 150);
    float4 texel8 = tex2D(Sampler8, PS.TexCoord * 150);
    float4 texel9 = tex2D(Sampler9, PS.TexCoord*30);*/
    
    float w = 0.25f;
    
    float4 det = lerp(0, texel1, clamp( 1 - (0.5 - t_dt.r)/w, 0, 1));
    det = lerp(det, texel2, clamp( 1 - (0.5 - t_dt.g)/w, 0, 1));
    det = lerp(det, texel3, clamp( 1 - (0.5 - t_dt.b)/w, 0, 1));
    det = lerp(det, texel4, clamp( 1 - (0.5 - t_dt.a)/w, 0, 1));
    /*det = lerp(det, texel5, clamp( 1 - (0.5 - t_dt.r*t_dt.g)/w, 0, 1));
    det = lerp(det, texel6, clamp( 1 - (0.5 - t_dt.g*t_dt.b)/w, 0, 1));
    det = lerp(det, texel7, clamp( 1 - (0.5 - t_dt.r*t_dt.b)/w, 0, 1));
    det = lerp(det, texel8, clamp( 1 - (0.5 - t_dt.b*t_dt.a)/w, 0, 1));*/
    
    float3 	detail	= det;//*PS.c0.a + PS.c1.a;
	
	// final-color
	float3	final 	= (light)*detail;

    // out
	return  float4	(final.r,final.g,final.b,1);
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