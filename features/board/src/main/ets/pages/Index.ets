
@Preview
@Entry
@Component
struct ABC {
  @State message: string ='Hello World'

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .alignItems(HorizontalAlign.End)
    }
    .height('100%')
  }
}