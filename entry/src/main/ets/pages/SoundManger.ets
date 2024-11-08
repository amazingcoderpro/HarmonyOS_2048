import { audio } from '@kit.AudioKit';
import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit'

export class SoundManger {
  soundPool: media.SoundPool | undefined = undefined;
  defaultPlayParameters: media.PlayParameters = {
    loop: 0, // 不循环播放
    rate: audio.AudioRendererRate.RENDER_RATE_NORMAL, // 正常倍速
    leftVolume: 0.5, // range = 0.0-1.0
    rightVolume: 0.5, // range = 0.0-1.0
    priority: 0, // 最低优先级
  }
  isMute: boolean = false;

  soundIdMap = new Map<string, number>(); // 存储所有加载的音频ID
  streamIdMap = new Map<string, number>(); // 存储所有加载的流ID

  async createSoundPool() {
    let audioRendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_GAME,
      rendererFlags: 1
    }

    // this.soundPool =  await media.createSoundPool(5, audioRendererInfo);
    media.createSoundPool(5, audioRendererInfo).then((soundPool: media.SoundPool) => {
      if (soundPool != null) {
        this.soundPool = soundPool;
        console.info('create SoundPool success');
        //注册监听
        this.soundPool.on('loadComplete', (soundId_: number) => {
          console.info('soundPool loadComplete, soundId: ' + soundId_);
        })

        this.soundPool.on('playFinished', () => {
          console.info("soundPool.play receive play finished message");
          // 可进行下次播放
        })

        this.soundPool.on('error', (error: BusinessError) => {
          console.info('soundPool error happened,message is :' + error.message + error.code.toString());
        })

      } else {
        console.error('create SoundPool fail');
      }
    }).catch((error: BusinessError) => {
      console.error(`soundpool catchCallback, error message:${error.message}`);
    });
  }

  loadAudios(audioNames: string[], suffix: string='.mp3') {
    audioNames.forEach((value, index) => {
      this.loadAudio(value, suffix);
    })
  }

  async loadAudio(audioName: string, suffix: string='.mp3') {
    let context = getContext(this); //沙箱路径
    context.resourceManager.getRawFd(audioName + suffix,
      (error: BusinessError, value: resourceManager.RawFileDescriptor) => {
        if (error != null) {
          console.error(`callback getRawFd failed error code: ${error.code}, message: ${error.message}.`);
        } else {
          let fd = value.fd;
          let offset = value.offset;
          let length = value.length;
          console.info('loadAudio---getRawFd: ' + fd);
          // uri='fd://' + (fd).toString()
          this.soundPool?.load(fd, offset, length).then((soundIdRet: number) => {
            if (soundIdRet !== undefined) {
              this.soundIdMap.set(audioName, soundIdRet);
            } else {
              console.error('loadAudio---soundPool.load returned undefined');
            }
          }).catch((err: BusinessError) => {
            console.error('loadAudio---catch error is ' + err.message);
          })
        }
      });
    } catch(error:BusinessError) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      console.error(`callback getRawFd failed, error code: ${code}, message: ${message}.`);
    }

  playSound(soundKey: string, playParameters: media.PlayParameters=this.defaultPlayParameters) {
    // 开始播放，这边play也可带播放播放的参数PlayParameters，请在音频资源加载完毕，即收到loadComplete回调之后再执行play操作
    if (this.isMute){
      return;
    }
    const soundId = this.soundIdMap?.get(soundKey);
    if (!soundId) {
      console.error('Sound ID for '+soundKey +' not found.');
      return;
    }

    let streamId: number = 0;
    console.info('before call soundPool.play, soundId: ' + soundId);
    this.soundPool?.play(soundId, playParameters, (error, streamID: number) => {
      if (error) {
        console.info(`play sound Error: errCode is ${error.code}, errMessage is ${error.message}`)
      } else {
        streamId = streamID;
        this.streamIdMap.set(soundKey, streamId);
        console.info('soundPool.play callback , soundId: ' + soundId, ', streamId: ' + streamId);
      }
    });

    // // 设置循环播放次数
    // await soundPool.setLoop(streamId, 2); // 播放3次
    // // 设置对应流的优先级
    // await soundPool.setPriority(streamId, 1);
    // // 设置音量
    // await soundPool.setVolume(streamId, 0.5, 0.5);
  }

  async stopSound(soundKey: string) {
    try {
      const streamId = this.streamIdMap?.get(soundKey);
      if (!streamId) {
        console.error('stopPlayAudio stream ID for '+soundKey +' not found.');
        return;
      }
      await this.soundPool?.stop(streamId);
      this.streamIdMap.delete(soundKey);
      } catch (error) {
        console.info('stopPlayAudio error: ' + error.message);
        return;
      }
  }

  stopSoundAll() {
    try {
      this.streamIdMap.forEach((value, key) => {
        let streamId = value;
        if (!streamId) {
          console.error('stopPlayAudio stream ID for ' + streamId + ' not found.');
          return;
        }
        this.soundPool?.stop(streamId);
      })
      this.streamIdMap.clear();
    } catch (error) {
      console.info('stopPlayAudio error: ' + error.message);
      return;
    }
  }

  unloadAll() {
    this.soundIdMap.forEach((value, key) => {
      this.soundPool?.unload(value);
    });
    this.soundIdMap.clear();
  }

  async releaseSoundPool() {
    // 停止播放
    // 卸载音频资源
    // for
    this.stopSoundAll();
    this.unloadAll();
    //关闭监听
    this.soundPool?.off('loadComplete');
    this.soundPool?.off('playFinished');
    this.soundPool?.off('error');
    // 释放SoundPool
    await this.soundPool?.release();
  }

}