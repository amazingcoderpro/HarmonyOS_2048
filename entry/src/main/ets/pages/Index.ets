import prompt from '@system.prompt';
// import { advertising, AutoAdComponent, identifier } from '@kit.AdsKit';
// import { hilog } from '@kit.PerformanceAnalysisKit';
import { AlertDialog } from '@kit.ArkUI'

PersistentStorage.persistProp("persistedData", new Map<string, number>([]));
let storage = LocalStorage.GetShared()


function getRandomNumber(): number {
  const numbers = [2, 2, 2, 4];
  // const numbers = [512,1024,2048,4096, 8192,16384];
  return numbers[Math.floor(Math.random() * numbers.length)];
}

function buildTwoDimensionalArray(row: number, col: number): number[][] {
  let result: number[][] = [];
  for (let i = 0; i < row; i++) {
    result[i] = [];
    for (let j = 0; j < col; j++) {
      result[i][j] = 0;
    }
  }
  return result;
}


@Entry(storage)
@Component
struct Index {
  @State @Watch('onTotalScoreChanged') totalScore: number = 0;
  @State @Watch('onGameOverChanged') isGameOver: boolean = false;
  @State numberItems: NumberItem[][] = [];
  @State soundOn: number = 1;
  @LocalStorageLink('RecordScore') recordScore: number = 0;
  @LocalStorageLink('RecordScoreHard') recordScoreHard: number = 0;
  @LocalStorageLink('RecordScoreSpeed') recordScoreSpeed: number = 0;
  @State numbers: number[][]=[]
  @State initRow: number = 4;
  @State initCol: number = 4;
  isFirstOverRecord: boolean = true;
  @State displayRecordScore: number = 0;
  private context = getContext(this) as Context;


  //广告相关的----begin
  // @State adParam: advertising.AdRequestParams = {
  //   // 广告类型：Banner广告
  //   adType: 8,
  //   // 'testw6vs28auh3'为测试专用的广告位ID，App正式发布时需要改为正式的广告位ID
  //   adId: 'testw6vs28auh3',
  //   // 广告位宽
  //   adWidth: 360,
  //   // 广告位高
  //   adHeight: 57,
  //   // 开放匿名设备标识符
  //   oaid: ''
  // };
  // private adOptions: advertising.AdOptions = {
  //   // 是否允许流量下载0：不允许，1：允许，不设置以广告主设置为准
  //   allowMobileTraffic: 0,
  //   // 是否希望根据 COPPA 的规定将您的内容视为面向儿童的内容: -1默认值，不确定 0不希望 1希望
  //   tagForChildProtection: -1,
  //   // 是否希望按适合未达到法定承诺年龄的欧洲经济区 (EEA) 用户的方式处理该广告请求： -1默认值，不确定 0不希望 1希望
  //   tagForUnderAgeOfPromise: -1,
  //   // 设置广告内容分级上限: W: 3+,所有受众 PI: 7+,家长指导 J:12+,青少年 A: 16+/18+，成人受众
  //   adContentClassification: 'A'
  // };
  // private displayOptions: advertising.AdDisplayOptions = {
  //   // 广告轮播的时间间隔，单位ms，取值范围[30000, 120000]
  //   refreshTime: 30000
  // }
  // private ratio: number = 1;
  // private adWidth: number = -1;
  // private adHeight: number = -1;


  // initBannerAds() {
  //   try {
  //     // 使用Promise回调方式获取OAID
  //     identifier.getOAID().then((data) => {
  //       this.adParam.oaid = data;
  //       hilog.info(0x0000, 'testTag', '%{public}s', `Succeeded in getting adsIdentifierInfo by promise`);
  //     }).catch((error: BusinessError) => {
  //       hilog.error(0x0000, 'testTag', '%{public}s',
  //         `Failed to get adsIdentifierInfo, code: ${error.code}, message: ${error.message}`);
  //     })
  //   } catch (error) {
  //     hilog.error(0x0000, 'testTag', '%{public}s', `Catch err, code: ${error.code}, message: ${error.message}`);
  //   }
  //
  //   if (this.adParam?.adWidth && typeof (this.adParam?.adWidth) === 'number' && this.adParam?.adWidth > 0) {
  //     this.adWidth = this.adParam?.adWidth;
  //   }
  //   if (this.adParam?.adHeight && typeof (this.adParam?.adHeight) === 'number' && this.adParam?.adHeight > 0) {
  //     this.adHeight = this.adParam?.adHeight;
  //   }
  //   if (this.adWidth > 0 && this.adHeight > 0) {
  //     this.ratio = this.adWidth / this.adHeight;
  //   }
  // }

  //广告相关的----end

  // 游戏困难模式选择
  @State txtGameLevel: string = "正常模式";
  @State @Watch('onGameLevelChanged') gameLevel: number = 0;
  @State arrowPosition: ArrowPosition = ArrowPosition.END
  dialogGameLevel: CustomDialogController|null = null;
  dialogGameOver: CustomDialogController|null = null;

  // 主题选择
  @State txtGameTheme: string = "数字主题";
  @State @Watch('onGameThemeChanged') gameTheme: number = 0;

  onGameThemeChanged() {
    //TODO: 游戏主题选择
  }

  onGameLevelChanged() {
    // 当前得分为 0 的话就不用弹窗提示了，直接变更游戏难度
    if (this.totalScore <= 0) {
      this.RestartGame();
      return;
    }

    let subTitle: string = "正常模式"
    if (this.gameLevel == 1) {
      subTitle = "困难模式";
    } else if (this.gameLevel == 2) {
      subTitle = "极速模式";
    }
    this.dialogGameLevel = this.createAlertDialog("变更游戏模式", "", "将结束本局游戏并自动保存得分记录\n确认以【"+subTitle+"】重新开局？", this.AfterGameLevelChanged, this)
    this.dialogGameLevel.open();
  }

  AfterGameLevelChanged(changed: boolean, self: Index=this) {
    self.dialogGameLevel?.close();
    if (changed) {
      self.RestartGame();
    }
  }

  onGameOverChanged() {
    if (this.isGameOver) {
      // prompt.showToast({
      //   message: "游戏结束了!"
      // })
      let subTitle = "本局得分: 【 "+this.totalScore.toString()+ " 】分！";
      let content: string = subTitle + "\n你真棒，再来一局吧！"
      if (this.totalScore > this.displayRecordScore) {
        content = subTitle + "\n太棒了，创造新纪录了，再来一局吧！"
      }
      this.dialogGameOver = this.createAlertDialog("游戏结束", "", content, this.AfterGameOver, this, "退出休息", "再来一局")
      this.dialogGameOver.open();
    } else {
      this.RestartGame();
    }
  }


  private createAlertDialog(title: string, secondaryTitle:string, content: string, callback: (result: boolean, self: Index)  => void, self: Index=this, pBtnName: string='取消', sBtnName:string='确认') {
      let dialogControllerConfirm: CustomDialogController = new CustomDialogController({
      builder: AlertDialog({
        primaryTitle: title,
        secondaryTitle: secondaryTitle,
        content: content,
        primaryButton: {
          value: pBtnName,
          action: () => {
            callback(false, self);
          },
        },
        secondaryButton: {
          value: sBtnName,
          role: ButtonRole.ERROR,
          action: () => {
            console.info('Callback when the second button is clicked')
            callback(true, self);
          }
        },
      }),
    })

    return dialogControllerConfirm;
  }

  textTimerController: TextTimerController = new TextTimerController()
  @State timerStatus: number = 0;
  @State strTimerStartBtn: string = "开始";
  @State visibilityState: Visibility = Visibility.Visible;


  private initNumberItems() {
    let randomCount: number = 1;
    if (this.gameLevel == 1) {
      randomCount = 2;
    }
    let tempNumbers = buildTwoDimensionalArray(this.initRow, this.initCol);
    let randomPos: number = Math.floor(Math.random() * this.initRow * this.initCol);
    let otherPos: number = randomPos;
    if (randomCount > 1) {
      let diff = Math.floor(Math.random() * this.initRow*this.initCol*0.5);
      if (randomPos >= diff ) {
        otherPos = randomPos - diff;
      }else {
        otherPos = randomPos + diff;
      }
    }

    for (let i = 0; i < this.initRow; i++) {
      tempNumbers[i] = [];
      for (let j = 0; j < this.initCol; j++) {
        if (i * this.initRow + j == randomPos || i * this.initRow + j == otherPos) {
          tempNumbers[i][j] = getRandomNumber();
        } else {
          tempNumbers[i][j] = 0;
        }
      }
    }

    let tempNumbersItems: NumberItem[][] = [];
    for (let i = 0; i < this.initRow; i++) {
      tempNumbersItems[i] = [];
      for (let j = 0; j < this.initCol; j++) {
        tempNumbersItems[i][j] = new NumberItem(tempNumbers[i][j]);
      }
    }

    this.numbers = tempNumbers;
    this.numberItems = tempNumbersItems;
  }


  aboutToAppear(): void {
    this.RestartGame();

    // 获取广告位ID
    // this.initBannerAds();
  }


  aboutToDisappear(): void {
  }

  onTotalScoreChanged() {
    let recordScore : number = this.recordScore;
    if (this.gameLevel == 1) {
      recordScore = this.recordScoreHard??0;
    } else if (this.gameLevel == 2) {
      recordScore = this.recordScoreSpeed??0;
    }
    if (this.totalScore > recordScore) {
      if (this.isFirstOverRecord && this.displayRecordScore>0) {
        this.isFirstOverRecord = false;
        prompt.showToast({ message: "创造新纪录了, 加油!" })
      }
      if (this.gameLevel == 0) {
        this.recordScore = this.totalScore;
      } else if (this.gameLevel == 1) {
        this.recordScoreHard = this.totalScore;
      } else if (this.gameLevel == 2) {
        this.recordScoreSpeed = this.totalScore;
      }
      this.context.eventHub.emit('UpdateRecordEvent', recordScore, this.gameLevel);
    }
    console.log('onTotalScoreChanged record score - ', this.recordScore.toString(), 'game level: ', this.gameLevel.toString());
  }

  AfterGameOver(restartGame: boolean = true, self: Index=this) {
    self.dialogGameOver?.close();
    if (restartGame) {
      self.RestartGame();
    }
  }

  OnRestartGame() {
    this.RestartGame();
  }

  RestartGame() {
    console.log('-------RestartGame------');
    this.totalScore = 0;
    this.isGameOver = false;
    this.isFirstOverRecord = true;
    this.displayRecordScore = this.recordScore;
    this.timerStatus = 0;
    this.strTimerStartBtn = '开始';
    this.textTimerController.reset();
    if (this.gameLevel == 1) {
      this.displayRecordScore = this.recordScoreHard??0;
    } else if (this.gameLevel == 2) {
      this.displayRecordScore = this.recordScoreSpeed??0;
    }

    this.initNumberItems();
  }

  build() {
    RelativeContainer() {
      Column({ space: 5 }) {
        Row({space: 5}) {
          Image($r('app.media.startIcon'))
            .width(60).height(60)
            .margin({ right: 10})

          Column() {
            Text('分数')
              .fontSize(16)
              .fontColor(0xeee3d7)
              .margin({ bottom: 5 })
              .alignRules({
                center: { anchor: '__container__', align: VerticalAlign.Center },
                middle: { anchor: '__container__', align: HorizontalAlign.Center }
              });
            Text(this.totalScore.toString())
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(0xfefefe)
              .alignRules({
                center: { anchor: '__container__', align: VerticalAlign.Center },
                middle: { anchor: '__container__', align: HorizontalAlign.Center }
              });
          }
          .width(120)
          .height(60)
          .backgroundColor(0xbbaea1)
          .borderRadius(5)
          .padding(5)
          .margin({ right: 20 })

          Column() {
            Text('最高分')
              .fontSize(16)
              .fontColor(0xeee3d7)
              .margin({ bottom: 5 })
              .alignRules({
                center: { anchor: '__container__', align: VerticalAlign.Center },
                middle: { anchor: '__container__', align: HorizontalAlign.Center }
              });
            Text(this.displayRecordScore.toString())
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(0xfefefe)
              .alignRules({
                center: { anchor: '__container__', align: VerticalAlign.Center },
                middle: { anchor: '__container__', align: HorizontalAlign.Center }
              });
          }
          .width(120)
          .height(60)
          .backgroundColor(0xbbaea1)
          .borderRadius(5)
          .padding(5)
        }.alignItems(VerticalAlign.Top)
        // .justifyContent(FlexAlign.SpaceEvenly)

        Row() {
          Text("重新\n开始")
            .fontSize(12)
            .backgroundColor(Color.Orange)
            .padding(5)
            .width(40)
            .height(40)
            .borderRadius(18)
            .textAlign(TextAlign.Center)
            .margin({ right: 30, left:10})
            .onClick(() => {
              this.OnRestartGame();
            });

          Column() {
            Select([{ value: '正常模式' },
              { value: '困难模式' },
              { value: '极速模式' }])
              .width(120)
              .selected(this.gameLevel)
              .value(this.txtGameLevel)
              .font({ size: 16, weight: 300 })
              .fontColor('#182431')
              .selectedOptionFont({ size: 14, weight: 200 })
              .optionFont({ size: 14, weight: 200 })
              .space(2)
              .arrowPosition(this.arrowPosition)
              .menuAlign(MenuAlignType.START, { dx: 0, dy: 0 })
              .optionWidth(100)
              .optionHeight(150)
              // .align(Alignment.Start)
              .onSelect((index: number, text?: string | undefined) => {
                console.info('Select:' + index)
                if (index != this.gameLevel) {
                  if (text) {
                    this.txtGameLevel = text;
                  }
                  this.gameLevel = index;
                }
              })
          }.margin({right: 20})

          Column() {
            // Text('游戏主题:')
            Select([{ value: '数字主题' },
              { value: '逆向思维' },
              { value: '进士及第' },
              { value: '士兵突击' }])
              .width(120)
              .selected(this.gameTheme)
              .value(this.txtGameTheme)
              .font({ size: 16, weight: 300 })
              .fontColor('#182431')
              .selectedOptionFont({ size: 14, weight: 200 })
              .optionFont({ size: 14, weight: 200 })
              .space(2)
              .arrowPosition(this.arrowPosition)
              .menuAlign(MenuAlignType.START, { dx: 0, dy: 0 })
              .optionWidth(100)
              .optionHeight(150)
              // .align(Alignment.Start)
              .onSelect((index: number, text?: string | undefined) => {
                console.info('Select:' + index)
                if (index != this.gameTheme) {
                  if (text) {
                    this.txtGameTheme = text;
                  }
                  this.gameTheme = index;
                }
              })
          }
        }
        .margin({top: 10, bottom: 10})
        .justifyContent(FlexAlign.Center)

        Row() {
          TextTimer({ isCountDown: true, count: 180000, controller: this.textTimerController })
            .format('mm:ss.SS')
            .fontColor(Color.Black)
            .fontSize(18)
            .onTimer((utc: number, elapsedTime: number) => {
              // console.info('Timer--:' + elapsedTime)
              if (elapsedTime >= 18000) {
                this.isGameOver = true;
              }
            })

          Button(this.strTimerStartBtn)
            .onClick(() => {
              if (this.timerStatus == 0) {
                this.timerStatus = 1; // 启动了
                this.strTimerStartBtn = '暂停';
                this.textTimerController.start()
              } else if (this.timerStatus == 1) {
                this.timerStatus = 2; //暂停了
                this.strTimerStartBtn = '继续';
                this.textTimerController.pause()
              } else if (this.timerStatus == 2) {
                this.timerStatus = 1; // 继续了
                this.strTimerStartBtn = '暂停';
                this.textTimerController.start()
              }
            })
            .width(40)
            .align(Alignment.Center)
            // .backgroundColor(0x027bff)
            .backgroundColor(0xf2b178)
            // .fontColor(0xffffff)
            .fontSize(12)
            .fontWeight(400)
            .borderRadius(8)
            .padding(3)
            .margin({ left: 20 })

        }.visibility(this.gameLevel != 2 ? Visibility.None : Visibility.Visible)


        MainGrid({ totalScore: this.totalScore, isGameOver: this.isGameOver, numbers: this.numbers,
          numberItems: this.numberItems, initRow: this.initRow, initCol: this.initCol,
          gameLevel: this.gameLevel, timerStatus: this.timerStatus} )
          .margin({ top: 10, bottom: 10 });
      }
      .width('100%')

      // 广告
      // if (this.adParam.oaid) {
      //   Stack({ alignContent: Alignment.Bottom }) {
      //     this.buildBannerView()
      //   }
      // }

    }
    .height('100%')
    .width('100%')
    .margin({ top: 20, bottom: 20 })

  }

  //
  // @Builder
  // buildBannerView() {
  //   Row() {
  //     AutoAdComponent({
  //       adParam: this.adParam,
  //       adOptions: this.adOptions,
  //       displayOptions: this.displayOptions,
  //       interactionListener: {
  //         onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
  //           hilog.info(0x0000, 'testTag', '%{public}s', `status is ${status}`);
  //           switch (status) {
  //             case AdStatus.AD_OPEN:
  //               hilog.info(0x0000, 'testTag', '%{public}s', 'Status is onAdOpen');
  //               break;
  //             case AdStatus.AD_CLICKED:
  //               hilog.info(0x0000, 'testTag', '%{public}s', 'Status is onAdClick');
  //               break;
  //             case AdStatus.AD_CLOSED:
  //               hilog.info(0x0000, 'testTag', '%{public}s', 'Status is onAdClose');
  //               this.visibilityState = Visibility.None;
  //               break;
  //             case AdStatus.AD_LOAD:
  //               hilog.info(0x0000, 'testTag', '%{public}s', 'Status is onAdLoad');
  //               break;
  //             case AdStatus.AD_FAIL:
  //               hilog.error(0x0000, 'testTag', '%{public}s', 'Status is onAdFail');
  //               this.visibilityState = Visibility.None;
  //               break;
  //           }
  //         }
  //       }
  //     })
  //   }
  //   .width('100%')
  //   .aspectRatio(this.ratio)
  //   .visibility(this.visibilityState)
  // }

}

class NumberItem {
  num: number = 0;
  numString: string = '';
  numColor: number = 0xfdfffe;
  bgColour: number = 0x2d2736;
  numSize: number = 20;
  themeMode: number = 0;//0-number, 1-daoxu, 2-kaoshi, 3-shibing,

  constructor(num: number) {
    this.num = num;
    this.numString = num > 0 ? num.toString() : '';


    switch (num) {
      case 0: {
        this.numColor = 0x786d63;
        this.bgColour = 0xcabeb2;
        this.numSize = 40;
        break;
      }
      case 2: {
        this.numColor = 0x736d61;
        this.bgColour = 0xefe4da;
        this.numSize = 40;
        break;
      }
      case 4: {
        this.numColor = 0x776c62;
        this.bgColour = 0xeaddc6;
        this.numSize = 40;
        break;
      }
      case 8: {
        this.numColor = 0xfefdfb;
        this.bgColour = 0xf2b178;
        this.numSize = 40;
        break;
      }
      case 16: {
        this.numColor = 0xfeffff;
        this.bgColour = 0xf6925d;
        this.numSize = 36;
        break;
      }
      case 32: {
        this.numColor = 0xfdfdfb;
        this.bgColour = 0xf57758;
        this.numSize = 36;
        break;
      }
      case 64: {
        this.numColor = 0xfdfffe;
        this.bgColour = 0xf2522d;
        this.numSize = 36;
        break;
      }
      case 128: {
        this.numColor = 0xfefeff;
        this.bgColour = 0xedce73;
        this.numSize = 32;
        break;
      }
      case 256: {
        this.numColor = 0xfeffff;
        this.bgColour = 0xe5d153;
        this.numSize = 32;
        break;
      }
      case 512: {
        this.numColor = 0xfffffe;
        this.bgColour = 0xcfa30d;
        this.numSize = 32;
        break;
      }
      case 1024: {
        this.numColor = 0xfbfcf0;
        this.bgColour = 0xe7c451;
        this.numSize = 28;
        break;
      }
      case 2048: {
        this.numColor = 0xfbfbea;
        this.bgColour = 0xdf6c37;
        this.numSize = 28;
        break;
      }
      case 4096: {
        this.numColor = 0xf5fbf6;
        this.bgColour = 0xfc4b45;
        this.numSize = 28;
        break;
      }
      case 8192: {
        this.numColor = 0xf5fbf6;
        this.bgColour = 0x812f33;
        this.numSize = 28;
        break;
      }
      case 16384: {
        this.numColor = 0xfdfffe;
        this.bgColour = 0x705e78;
        this.numSize = 24;
        break;
      }
      case 32768: {
        this.numColor = 0xfdfffe;
        this.bgColour = 0xa5aaa3;
        this.numSize = 24;
        break;
      }

    }
  }
}

@Preview
@Component
struct MainGrid {
  @Link totalScore: number;
  @Link isGameOver: boolean;
  @Link numberItems: NumberItem[][];
  @Link numbers: number[][];
  @Link initRow: number;
  @Link initCol: number;
  @Link gameLevel: number; //0-normal, 1-hard, 2-speed
  @Link timerStatus: number;

  screenStartX: number = 0
  screenStartY: number = 0
  lastScreenX: number = 0
  lastScreenY: number = 0

  private eraseZeroOf2DArray(numbers: number[][], moveTo: string, row: number = 4, col: number = 4): number[][] {
    let newArray = buildTwoDimensionalArray(row, col);
    if (moveTo == 'left') {
      for (let i = 0; i < row; i++) {
        let newPos: number = 0;
        for (let j = 0; j < col; j++) {
          if (numbers[i][j] != 0) {
            newArray[i][newPos] = numbers[i][j];
            newPos++;
          }
        }
      }
    } else if (moveTo == 'right') {
      for (let i = 0; i < row; i++) {
        let newPos: number = col - 1;
        for (let j = col - 1; j >= 0; j--) {
          if (numbers[i][j] != 0) {
            newArray[i][newPos] = numbers[i][j];
            newPos--;
          }
        }
      }
    } else if (moveTo == 'up') {
      for (let i = 0; i < col; i++) {
        let newPos: number = 0;
        for (let j = 0; j < row; j++) {
          if (numbers[j][i] != 0) {
            newArray[newPos][i] = numbers[j][i];
            newPos++;
          }
        }
      }
    } else if (moveTo == 'down') {
      for (let i = 0; i < col; i++) {
        let newPos: number = row - 1;
        for (let j = row - 1; j >= 0; j--) {
          if (numbers[j][i] != 0) {
            newArray[newPos][i] = numbers[j][i];
            newPos--;
          }
        }
      }
    }

    return newArray;
  }

  private merge2DArray(numbers: number[][], moveTo: string, row: number = 4, col: number = 4): MergeResult {
    let mergedArray = buildTwoDimensionalArray(row, col);
    let getScore: number = 0;
    if (moveTo == 'left') {
      for (let i = 0; i < row; i++) {
        let newPos: number = 0;
        for (let j = 0; j < col; j++) {
          if (numbers[i][j] != 0) {
            if (j < col - 1 && numbers[i][j] == numbers[i][j+1]) {
              mergedArray[i][newPos] = numbers[i][j] * 2;
              getScore += mergedArray[i][newPos];
              numbers[i][j+1] = 0;
            } else {
              mergedArray[i][newPos] = numbers[i][j];
            }
            newPos++;
          }
        }
      }
    } else if (moveTo == 'right') {
      for (let i = 0; i < row; i++) {
        let newPos: number = col - 1;
        for (let j = col - 1; j >= 0; j--) {
          if (numbers[i][j] != 0) {
            if (j >= 1 && numbers[i][j] == numbers[i][j-1]) {
              mergedArray[i][newPos] = numbers[i][j] * 2;
              getScore += mergedArray[i][newPos];
              numbers[i][j-1] = 0;
            } else {
              mergedArray[i][newPos] = numbers[i][j];
            }
            newPos--;
          }
        }
      }
    } else if (moveTo == 'up') {
      for (let j = 0; j < col; j++) {
        let newPos: number = 0;
        for (let i = 0; i < row; i++) {
          if (numbers[i][j] != 0) {
            if (i < row - 1 && numbers[i][j] == numbers[i+1][j]) {
              mergedArray[newPos][j] = numbers[i][j] * 2;
              getScore += mergedArray[newPos][j];
              numbers[i+1][j] = 0;
            } else {
              mergedArray[newPos][j] = numbers[i][j];
            }
            newPos++;
          }
        }
      }
    } else if (moveTo == 'down') {
      for (let j = 0; j < col; j++) {
        let newPos: number = row - 1;
        for (let i = row - 1; i >= 0; i--) {
          if (numbers[i][j] != 0) {
            if (i >= 1 && numbers[i][j] == numbers[i-1][j]) {
              mergedArray[newPos][j] = numbers[i][j] * 2;
              getScore += mergedArray[newPos][j];
              numbers[i-1][j] = 0;
            } else {
              mergedArray[newPos][j] = numbers[i][j];
            }
            newPos--;
          }
        }
      }
    }

    return { mergedArray, getScore } as MergeResult;
  }

  private addOneRandomNumber(numbers: number[][], randomPos :number, row: number = 4, col: number = 4) {
    let randomNum: number = getRandomNumber();
    let emptyStep = 0;
    let doneFlag: boolean = false;
    for (let i = 0; i < row; i++) {
      if (doneFlag) {
        break;
      }
      for (let j = 0; j < col; j++) {
        if (numbers[i][j] == 0) {
          if (emptyStep == randomPos) {
            numbers[i][j] = randomNum;
            doneFlag = true;
            break;
          }
          emptyStep++;
        }
      }
    }
    return numbers;
  }

  private addRandomNumber(numbers: number[][], row: number = 4, col: number = 4, randomCount: number = 1) {
    let emptyPosCount: number = this.calcEmptyPosCount(numbers, row, col);
    if (emptyPosCount <= 0) {
      return numbers;
    }
    // 最多增加随机数的次数不能大于空位数
    if (randomCount > emptyPosCount) {
      randomCount = emptyPosCount;
    }

    let index : number = 1;
    let lastLength: number = 0;
    while (index <= randomCount) {
      let currentLength = Math.floor(emptyPosCount*index/randomCount);
      if(currentLength-lastLength <= 0) {
        break;
      }
      let randomPos: number = Math.floor(Math.random() * (currentLength-lastLength));
      console.log('---emptyPosCount = ', emptyPosCount, ', random range=', currentLength-lastLength, 'randomPos=', randomPos+lastLength);
      numbers = this.addOneRandomNumber(numbers, randomPos+lastLength, row, col)
      lastLength = currentLength;
      index++;
    }

    return numbers;
  }

  private calcEmptyPosCount(numbers: number[][], row: number = 4, col: number = 4) {
    let emptyPosCount: number = 0;
    for (let i = 0; i < row; i++) {
      for (let j = 0; j < col; j++) {
        if (numbers[i][j] == 0) {
          emptyPosCount++;
        }
      }
    }
    return emptyPosCount;
  }

  private judgeGameIsOver(numbers: number[][], row: number = 4, col: number = 4) {
    let emptyPosCount: number = 0;
    for (const moveTo of ['left', 'right', 'up', 'down']) {

      let result = this.merge2DArray(this.eraseZeroOf2DArray(numbers, moveTo, row, col), moveTo, row, col);
      emptyPosCount += this.calcEmptyPosCount(result.mergedArray);
      if (emptyPosCount > 0) {
        return false;
      }
    }
    return true;
  }

  private updateNumberItems(moveTo: string, row: number = 4, col: number = 4) {
    // console.info('updateNumberItems before process, numbers=', JSON.stringify(this.numbers));
    let newArrayAfterEraseZero: number[][] = this.eraseZeroOf2DArray(this.numbers, moveTo, row, col);
    // console.info('updateNumberItems after erase zero, numbers=', JSON.stringify(newArrayAfterEraseZero));
    let result = this.merge2DArray(newArrayAfterEraseZero, moveTo, row, col);

    // console.info('updateNumberItems after merge, numbers=', JSON.stringify(result.mergedArray));
    // 操作(消0+同数合并)之后数组没有任何变化不用增加随机数，也不用更新，此时如果没有空格，这游戏结束
    if (JSON.stringify(this.numbers) == JSON.stringify(result.mergedArray)) {
      if (this.judgeGameIsOver(result.mergedArray, row, col)) {
        this.isGameOver = true;
      }
      return;
    }

    this.totalScore += result.getScore;
    let randomCount: number = 1;
    if (this.gameLevel == 1) {
      randomCount = 2;
    }
    let newArrayAfterRandom: number[][] = this.addRandomNumber(result.mergedArray, row, col, randomCount);

    let newNumberItems: NumberItem[][] = [];
    for (let i = 0; i < row; i++) {
      newNumberItems[i] = [];
      for (let j = 0; j < col; j++) {
        newNumberItems[i][j] = new NumberItem(newArrayAfterRandom[i][j]);
      }
    }
    this.numbers = newArrayAfterRandom;
    this.numberItems = newNumberItems;
  }

  aboutToAppear(): void {

  }

  build() {
    Grid() {
      ForEach(this.numberItems, (row: NumberItem[]) => {
        ForEach(row, (numberItem: NumberItem) => {
          GridItem() {
            Text(numberItem.numString)
              .fontSize(numberItem.numSize)
              .fontColor(numberItem.numColor)
              .backgroundColor(numberItem.bgColour)
              .textAlign(TextAlign.Center)
              .fontWeight(FontWeight.Bold)
              .fontFamily('HarmonyHeiTi-Bold')
              .width('100%')
              .height('100%')
              .borderRadius(5)
          }

          // GridItem() {
          //   Text('')
          //     .fontSize(32)
          //     .fontColor(0x786d63)
          //     .backgroundColor(0xefe4da)
          //     .textAlign(TextAlign.Center)
          //     .width('100%')
          //     .height('100%')
          //     .fontFamily('HarmonyHeiTi-Bold')
          //     .fontWeight(700)
          // }
        })
      })
    }
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr 1fr')
    .columnsGap(10)
    .rowsGap(10)
    .width('90%')
    .padding(10)
    .backgroundColor(0xb8aca0)
    .height(350)
    .borderRadius(5)
    .onTouch((e) => {
      if (e.type === TouchType.Down && e.touches.length > 0) { // 触摸开始，记录初始位置
        this.screenStartX = e.touches[0].screenX;
        this.screenStartY = e.touches[0].screenY;
      } else if (e.type === TouchType.Up && e.changedTouches.length > 0) { // 当手指抬起时，更新最后的位置
        this.lastScreenX = e.changedTouches[0].screenX;
        this.lastScreenY = e.changedTouches[0].screenY;
      } else if (e.type === TouchType.Move && e.changedTouches.length > 0) { // 当手指移动时，更新最后的位置
        this.lastScreenX = e.changedTouches[0].screenX;
        this.lastScreenY = e.changedTouches[0].screenY;
      }
    })
    .gesture(
      SwipeGesture({ direction: SwipeDirection.All })
        .onAction((event: GestureEvent) => {
          // 判断游戏是否结束或者暂停
          if (this.isGameOver ) {
            return;
          }
          if(this.gameLevel==2 && this.timerStatus!=1) {
            prompt.showToast({
              message: "请先开启倒计时!"
            })
            return;
          }
          const swipeX = this.lastScreenX - this.screenStartX;
          const swipeY = this.lastScreenY - this.screenStartY;
          // 判断滑动方向
          let directionText = '';
          if (Math.abs(swipeX) > Math.abs(swipeY)) {
            if (swipeX > 0) {
              directionText = 'right'; // 向右滑动
            } else {
              directionText = 'left'; // 向左滑动
            }
          } else {
            if (swipeY > 0) {
              directionText = 'down'; // 向下滑动
            } else {
              directionText = 'up'; // 向上滑动
            }
          }

          // console.info('====滑动方向:', directionText);
          this.updateNumberItems(directionText)
          // console.info('====起点x:', this.screenStartX);
          // console.info('====起点y:', this.screenStartY);
          // console.info('====终点x:', this.lastScreenX);
          // console.info('====终点y:', this.lastScreenY);

          // 清除开始位置记录，准备下一次滑动判断
          this.screenStartX = 0;
          this.screenStartY = 0;
        })
    )
  }
}

interface MergeResult {
  mergedArray: number[][];
  getScore: number;
}


enum AdStatus {
  AD_LOAD = 'onAdLoad',
  AD_FAIL = 'onAdFail',
  AD_OPEN = 'onAdOpen',
  AD_CLICKED = 'onAdClick',
  AD_CLOSED = 'onAdClose',
  AD_REWARDED = 'onAdReward',
  AD_VIDEO_START = 'onVideoPlayBegin',
  AD_COMPLETED = 'onVideoPlayEnd'
}


