
void drawCompressedPlot(PGraphics g, float[] relativeValues, int w, int h)
{
  int count = relativeValues.length;
  
  g.noFill();
  g.beginShape();
  for (int i = 0; i < count; ++i)
  {
    float fx = map(i, 0, frames.size(), 0, w);
    float fy = h - relativeValues[i] * h;
    g.vertex(fx, fy);
  }
  g.endShape();
}

void drawMovingPlot(PGraphics g, float[] relativeValues, float percent, int w, int h)
{
  int count = relativeValues.length;
  int onscreenCount = ceil(w * plotFramesPerDot);
  int offscreenCount = count - onscreenCount;
  
  g.noFill();
  g.beginShape();
  for (int onscreenIndex = 0; onscreenIndex < onscreenCount; ++onscreenIndex)
  {
    int index = onscreenIndex + round(percent * offscreenCount);
    if (index < 0)
      continue;
    if (index >= relativeValues.length)
      break;
      
    float fx = onscreenIndex / plotFramesPerDot;
    float fy = h - relativeValues[index] * h;
    g.vertex(fx, fy);
  }
  g.endShape();
}


interface ICache
{
  void update();
}

class FrameValueCache implements ICache
{
  float[] values;
  
  IFrameValueCalc calc;
  
  boolean normalize;
  
  FrameValueCache(IFrameValueCalc calc, boolean normalize)
  {
    this.calc = calc;
    this.normalize = normalize;
  }
  
  void update()
  {
    float[] newValues = new float[frames.size()];
    float max = MIN_INT;
    float min = MAX_INT;
    for (int i = 0; i < frames.size(); ++i)
    {
      float value = calc.getFrameValue(frames.get(i));
      newValues[i] = value;
      max = max(max, value);
      min = min(min, value);
    }
    
    if (normalize)
      values = map(newValues, min, max, 0, 1);
    else
      values = newValues;
  }
}

<T extends ICache> T register(T cache)
{
  caches.add(cache);
  return cache;
}


interface IFrameValueCalc
{
  float getFrameValue(PhysicalFrame frame);
}

/// Concrete frame value calculations

class FrameLengthCalc implements IFrameValueCalc
{
  float getFrameValue(PhysicalFrame frame)
  {
    return frame.header.frameLengthInBytes;
  }
}

class AverageAllGranuleLengthCalc implements IFrameValueCalc
{
  float getFrameValue(PhysicalFrame frame)
  {
    float sum = 0;
    for (GranuleChannelSideInformation gcInfo : frame.sideInformation.gcSideInfo)
      sum += gcInfo.par23length;
    return sum / frame.sideInformation.gcSideInfo.length;
  }
}

class AverageChannelGranuleLengthCalc implements IFrameValueCalc
{
  int channel;
  
  AverageChannelGranuleLengthCalc(int channel)
  {
    this.channel = channel;
  }
  
  float getFrameValue(PhysicalFrame frame)
  {
    SideInformation sideInfo = frame.sideInformation;
    if (channel >= sideInfo.channelCount)
      return 0;
    
    float sum = 0;
    for (int granule = 0; granule < 2; ++granule)
      sum += sideInfo.gcSideInfo[granule * sideInfo.channelCount + channel].par23length;
    return sum / 2;
  }
}


class AverageAllGranuleGlobalGainCalc implements IFrameValueCalc
{
  float getFrameValue(PhysicalFrame frame)
  {
    float sum = 0;
    for (GranuleChannelSideInformation gcInfo : frame.sideInformation.gcSideInfo)
      sum += gcInfo.globalGain;
    return sum / frame.sideInformation.gcSideInfo.length;
  }
}

class AverageChannelGranuleGlobalGainCalc implements IFrameValueCalc
{
  int channel;
  
  AverageChannelGranuleGlobalGainCalc(int channel)
  {
    this.channel = channel;
  }
  
  float getFrameValue(PhysicalFrame frame)
  {
    SideInformation sideInfo = frame.sideInformation;
    if (channel >= sideInfo.channelCount)
      return 0;
    
    float sum = 0;
    for (int granule = 0; granule < 2; ++granule)
      sum += sideInfo.gcSideInfo[granule * sideInfo.channelCount + channel].globalGain;
    return sum / 2;
  }
}


//new float[frames.size()];
    //for (int i = 0; i < frames.size(); ++i)
    //  frameValues[i] = frameValueCalc.getValue(frames.get(i));