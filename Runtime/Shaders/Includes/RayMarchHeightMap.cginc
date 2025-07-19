#ifndef RAYMARCHHEIGHTMAP_INCLUDED
#define RAYMARCHHEIGHTMAP_INCLUDED

//To try to fix unable to unroll errors
#pragma exclude_renderers d3d11_9x
#pragma exclude_renderers d3d9

//////////////// Ray March HeightMap Function ///////////////////////////

//** Tex               **// Input Texture Object
//** startZ            **// Input float for start height of texture
//** UV                **// Input float2 containing UVs
//** NumSteps          **// Input float for Max Steps
//** StepSize          **// Input float for ray step size
//** TraceVec          **// Input float3 for TraceVector, scaled by StepSize
//** bias              **// Input float for ray starting bias
//** heightscale       **// Input float for heightmap scale
//** TemporalJitter    **// Input bool (using int) to toggle Temporal Jitter
//** threshold         **// Input float for particle density
//** channel           **// Input float4 to select texture channel

void RayMarchHeightMap_float(UnityTexture2D Tex, float startZ, float2 UV, float NumSteps, float StepSize, float3 TraceVec, float bias, float heightscale, bool TemporalJitter, float threshold, float4 channel, out float accum)
{
    accum = 0;
    
    if (startZ <= threshold)
        return;

    float TimeLerp = 1;
    float DepthDiff = 0;
    float LastDiff = -bias;

//We scale Z by 2 since the heightmap represents two halves of as symmetrical volume texture, split along Z where texture = 0
    float3 RayStepUVz = float3(TraceVec.x, TraceVec.y, TraceVec.z * 2);

    float3 RayUVz = float3(UV, (startZ));


 //   if (TemporalJitter)
 //   {
	//// jitter the starting position
 //       int3 randpos = int3(Parameters.SvPosition.xy, View.StateFrameIndexMod8);
 //       float rand = float(Rand3DPCG16(randpos).x) / 0xffff;
 //       RayUVz += RayStepUVz * rand;
 //   }

    int i = 0;
    
    [loop] //To try to fix unable to unroll errors
    while (i < NumSteps)
    {

        RayUVz += RayStepUVz;
        RayUVz.xy = saturate(RayUVz.xy);
        //float SampleDepth = dot(channel, Tex.SampleLevel(Tex, RayUVz.xy, 0));
        float SampleDepth = dot(channel, SAMPLE_TEXTURE2D(Tex, Tex.samplerstate, RayUVz.xy)) * heightscale;
        DepthDiff = abs(RayUVz.z) - abs(SampleDepth);


        if (DepthDiff <= 0)
        {

            if (LastDiff > 0)
            {
                TimeLerp = saturate(LastDiff / (LastDiff - DepthDiff));
                accum += StepSize * (1 - TimeLerp);
				//accum+=StepSize;
            }
            else
            {
                accum += StepSize;
            }
        }
        else if (LastDiff <= 0)
        {
            TimeLerp = saturate(LastDiff / (LastDiff - DepthDiff));
            accum += StepSize * (TimeLerp);
			//accum+=StepSize;
        }

        LastDiff = DepthDiff;

        i++;
    }


//Run one more iteration outside of the loop. Using the Box Intersection in the material graph, we precompute the number of whole steps that can be run which leaves one final 'short step' which is the remainder that is traced here. This was cheaper than checking or clamping the UVs inside of the loop.
    RayUVz += RayStepUVz;
    RayUVz.xy = saturate(RayUVz.xy);
    //float SampleDepth = dot(channel, Tex.SampleLevel(TexSampler, RayUVz.xy, 0));
    float SampleDepth = dot(channel, SAMPLE_TEXTURE2D(Tex, Tex.samplerstate, RayUVz.xy)) * heightscale;
    DepthDiff = abs(RayUVz.z) - abs(SampleDepth);


    if (DepthDiff <= 0)
    {
        accum += StepSize;
    }
    else if (LastDiff <= 0)
    {
        TimeLerp = saturate(LastDiff / (LastDiff - DepthDiff));
        accum += StepSize * (TimeLerp);
    }
}

#endif