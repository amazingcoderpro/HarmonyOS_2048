
import prompt from '@system.prompt';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State @Watch('onTotalScoreChanged') totalScore: number = 0;
  @State @Watch('OnGameOver') gameOver: boolean = false;
  recordScore: number = 100;
  isPromptOverRecord: boolean = false;

  onTotalScoreChanged(){
    if(this.totalScore>this.recordScore){
      if(!this.isPromptOverRecord) {
        prompt.showToast({
          message:"创纪录了, 加油"
        })
        this.isPromptOverRecord=true;
      }
      this.recordScore = this.totalScore;
    }
  }

  OnGameOver(){
    if(this.gameOver){
      prompt.showToast({
        message:"游戏结束了"
      })
    }
  }

  build() {
    RelativeContainer() {
      Column({ space: 5 }) {
        Text(this.totalScore.toString())
          .id('HelloWorld')
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          });

        MainGrid({totalScore: this.totalScore, gameOver: this.gameOver});
      }
      .width('100%')
      .margin({ top: 5 })



    }
    .height('100%')
    .width('100%')

  }
}

class NumberItem {
  num: number = 0;
  numString: string = '';
  numColor: number = 0xF9CF93;
  bgColour: number = 0xF9CF93;
  numSize: number = 16;

  constructor(num: number) {
    this.num = num;
    this.numString = num>0 ? num.toString() : '';
    switch (num) {
      case 0: {
        this.numColor = 0x786d63;
        this.bgColour = 0xccc0b3;
        this.numSize = 32;
        break;
      }
      case 2: {
        this.numColor = 0x786d63;
        this.bgColour = 0xefe4da;
        this.numSize = 32;
        break;
      }
      case 4: {
        this.numColor = 0x796e67;
        this.bgColour = 0xeaddbe;
        this.numSize = 32;
        break;
      }
      case 8: {
        this.numColor = 0xfefdfb;
        this.bgColour = 0xf2b178;
        this.numSize = 32;
        break;
      }
      case 16: {
        this.numColor = 0xfeffff;
        this.bgColour = 0xf6925d;
        this.numSize = 32;
        break;
      }
      case 32: {
        this.numColor = 0xfdfdfb;
        this.bgColour = 0xf57758;
        this.numSize = 32;
        break;
      }
      case 64: {
        this.numColor = 0xfdfffe;
        this.bgColour = 0xf2522d;
        this.numSize = 32;
        break;
      }
    }
  }

}
@Preview
@Component
struct MainGrid {
  @Link totalScore: number;
  @Link gameOver: boolean;
  @State numberItems: NumberItem[][] = [];
  screenStartX: number = 0
  screenStartY: number = 0
  lastScreenX: number = 0
  lastScreenY: number = 0
  initRow: number = 4;
  initCol: number = 4;
  numbers: number[][] = [
    [0,2,0,16],
    [0,4,0,0],
    [0,0,4,0],
    [0,0,8,0]
  ]


  private initNumberItems(){
    let randomPos: number = Math.floor(Math.random() * this.initRow*this.initCol);
    // console.log(randomPos.toString())
    for (let i = 0; i < this.initRow; i++) {
      this.numbers[i] = [];
      for (let j = 0; j < this.initCol; j++) {
        if (i*this.initRow+j == randomPos) {
          this.numbers[i][j] = this.getRandomNumber();
        }else {
          this.numbers[i][j]=0;
        }
      }
    }
    // console.log(JSON.stringify(this.numbers)); // 将二维数组转换为字符串

    this.numberItems = [];
    for (let i = 0; i < 4; i++) {
      this.numberItems[i] = [];
      for (let j = 0; j < 4; j++) {
        this.numberItems[i][j] = new NumberItem(this.numbers[i][j]);
      }
    }
  }

  private buildTwoDimensionalArray(row: number, col: number): number[][] {
    let result: number[][] = [];
    for (let i = 0; i < row; i++) {
      result[i] = [];
      for (let j = 0; j < col; j++) {
        result[i][j] = 0;
      }
    }
    return result;
  }

  private eraseZeroOf2DArray(numbers: number[][], moveTo: string, row: number = 4, col: number = 4): number[][] {
    let newArray = this.buildTwoDimensionalArray(row, col);
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
        let newPos: number = col-1;
        for (let j = col-1; j >= 0; j--) {
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
        let newPos: number = row-1;
        for (let j = row-1; j >= 0; j--) {
          if (numbers[j][i] != 0) {
            newArray[newPos][i] = numbers[j][i];
            newPos--;
          }
        }
      }
    }

    return newArray;
  }



  private merge2DArray(numbers: number[][], moveTo: string, row: number = 4, col: number = 4): MergeResult{
    let mergedArray = this.buildTwoDimensionalArray(row, col);
    let getScore: number = 0;
    if (moveTo == 'left') {
      for (let i = 0; i < row; i++) {
        let newPos:number = 0;
        for (let j = 0; j < col; j++) {
          if (numbers[i][j] != 0) {
            if (j<col-1 && numbers[i][j] == numbers[i][j+1]) {
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
        let newPos:number = col-1;
        for (let j = col - 1; j >= 0; j--) {
          if (numbers[i][j] != 0) {
            if (j>=1 && numbers[i][j] == numbers[i][j-1]) {
              mergedArray[i][newPos] = numbers[i][j]*2;
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
      for (let j=0; j < col; j++) {
        let newPos:number = 0;
        for (let i=0; i< row; i++) {
          if (numbers[i][j] !=0 ) {
            if (i<row-1 && numbers[i][j] == numbers[i+1][j]) {
              mergedArray[newPos][j] = numbers[i][j] *2;
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
      for (let j=0; j < col; j++) {
        let newPos:number = row-1;
        for (let i=row-1; i>=0; i--) {
          if (numbers[i][j] !=0 ) {
            if (i>=1 && numbers[i][j] == numbers[i-1][j]) {
              mergedArray[newPos][j] = numbers[i][j] *2;
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

    return {mergedArray, getScore} as MergeResult;
  }
  private getRandomNumber(): number {
    const numbers = [2,2,2,4];
    return numbers[Math.floor(Math.random() * numbers.length)];
  }

  private addRandomNumber(numbers: number[][], row:number=4, col:number=4, randomCount:number=1) {
    let emptyPosCount: number = this.calcEmptyPosCount(numbers, row, col);
    let randomPos:number = Math.floor(Math.random() * emptyPosCount)
    let randomNum:number = this.getRandomNumber();

    let emptyStep = 0;
    let doneFlag:boolean = false;
    for(let i=0; i<row; i++) {
      if(doneFlag) break;
      for (let j=0; j<col; j++) {
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
    console.info('in addRandomNumber: randomPos=', randomPos, ', randomNum=', randomNum, 'new numbers=', JSON.stringify(numbers));
    return numbers;
  }
  private calcEmptyPosCount(numbers:number[][], row: number=4, col: number=4) {
    let emptyPosCount: number = 0;
    for(let i=0; i<row; i++) {
      for (let j=0; j<col; j++) {
        if (numbers[i][j] == 0) {
          emptyPosCount++;
        }
      }
    }
    return emptyPosCount;
  }

  private isGameOver(numbers:number[][], row: number=4, col: number=4) {
    let emptyPosCount:number = 0;
    for (const moveTo of ['left', 'right', 'up', 'down']) {

      let result = this.merge2DArray(this.eraseZeroOf2DArray(numbers, moveTo, row, col), moveTo, row, col);
      emptyPosCount += this.calcEmptyPosCount(result.mergedArray);
      if (emptyPosCount>0) {
        return false;
      }
    }

    return true;
  }
  private updateNumberItems(moveTo: string, row: number = 4, col: number = 4){
    console.info('updateNumberItems before process, numbers=', JSON.stringify(this.numbers));
    let newArrayAfterEraseZero: number[][] = this.eraseZeroOf2DArray(this.numbers, moveTo, row, col);
    console.info('updateNumberItems after erase zero, numbers=', JSON.stringify(newArrayAfterEraseZero));
    let result = this.merge2DArray(newArrayAfterEraseZero, moveTo, row, col);

    console.info('updateNumberItems after merge, numbers=', JSON.stringify(result.mergedArray));
    // 操作(消0+同数合并)之后数组没有任何变化不用增加随机数，也不用更新，此时如果没有空格，这游戏结束
    if (JSON.stringify(this.numbers) == JSON.stringify(result.mergedArray)) {
      if (this.isGameOver(result.mergedArray, row, col)) {
        this.gameOver = true;
      }

      return;
    }

    this.totalScore += result.getScore;
    let newArrayAfterRandom: number[][] = this.addRandomNumber(result.mergedArray, row, col);

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
    this.initNumberItems();
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
                .fontWeight(700)
                .fontFamily('HarmonyHeiTi-Bold')
                .width('100%')
                .height('100%')
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
      .backgroundColor(0xbbaea2)
      .height(300)
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

            console.info('====滑动方向:', directionText);
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



