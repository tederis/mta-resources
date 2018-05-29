//
// tex_matrix.fx
//


//-------------------------------------------
// Returns a translation matrix
//-------------------------------------------
float3x3 makeTranslationMatrix ( float2 pos )
{
    return float3x3(
                    1, 0, 0,
                    0, 1, 0,
                    pos.x, pos.y, 1
                    );
}


//-------------------------------------------
// Returns a rotation matrix
//-------------------------------------------
float3x3 makeRotationMatrix ( float angle )
{
    float s = sin(angle);
    float c = cos(angle);
    return float3x3(
                    c, s, 0,
                    -s, c, 0,
                    0, 0, 1
                    );
}


//-------------------------------------------
// Returns a scale matrix
//-------------------------------------------
float3x3 makeScaleMatrix ( float2 scale )
{
    return float3x3(
                    scale.x, 0, 0,
                    0, scale.y, 0,
                    0, 0, 1
                    );
}


//-------------------------------------------
// Returns a combined matrix of doom
//-------------------------------------------
float3x3 makeTextureTransform ( float2 prePosition, float2 scale, float2 scaleCenter, float rotAngle, float2 rotCenter, float2 postPosition )
{
    float3x3 matPrePosition = makeTranslationMatrix( prePosition );
    float3x3 matToScaleCen = makeTranslationMatrix( -scaleCenter );
    float3x3 matScale = makeScaleMatrix( scale );
    float3x3 matFromScaleCen = makeTranslationMatrix( scaleCenter );
    float3x3 matToRotCen = makeTranslationMatrix( -rotCenter );
    float3x3 matRot = makeRotationMatrix( rotAngle );
    float3x3 matFromRotCen = makeTranslationMatrix( rotCenter );
    float3x3 matPostPosition = makeTranslationMatrix( postPosition );

    float3x3 result =
                    mul(
                    mul(
                    mul(
                    mul(
                    mul(
                    mul(
                    mul(
                        matPrePosition
                        ,matToScaleCen)
                        ,matScale)
                        ,matFromScaleCen)
                        ,matToRotCen)
                        ,matRot)
                        ,matFromRotCen)
                        ,matPostPosition)
                    ;
    return result;
}
