import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { lang } from '@kit.ArkTS';
// import { lang } from '@kit.ArkTS';
// import abilityContext from '@ohos.ability.abilityContext';
// import abilityContext from '@system.ability.abilityContext';
// import prompt from '@ohos.data.prompt';
import prompt from '@system.prompt';
import { TipsDialog, SelectDialog, ConfirmDialog, AlertDialog, LoadingDialog, CustomContentDialog } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit';
import data from '@ohos.telephony.data';

let dataPreferences: preferences.Preferences | null = null;


interface StorageOptions {
  RecordScore: number;
  // 其他属性...
}

export default class EntryAbility extends UIAbility {
  sharedPara: Record<string, number> = {
    'RecordScore': 0
  };
  storage: LocalStorage = new LocalStorage(this.sharedPara);

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    this.loadAppData();
    this.registerEvent();
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
    this.saveAppData();
    this.unregisterEvent();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', this.storage, (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');

    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
    this.saveAppData();
  }

  loadAppData() {
    // 加载得分记录
    this.getValueFromPreferences("RecordScore", "", "sync");
    // 加载其他
  }

  saveAppData() {
    // 保存记录
    this.saveRecordScore();
    // 保存其他
  }

  registerEvent() {
    this.context.eventHub.on('UpdateRecordEvent', this.updateRecordScore);
  }

  unregisterEvent() {
    this.context.eventHub.off('UpdateRecordEvent', this.updateRecordScore);
  }

  saveRecordScore() {
    // 保存记录
    let recordScore: number | undefined = this.storage.get<number>("RecordScore");
    let score: number = recordScore ?? 0;
    this.saveValueToPreferences("RecordScore", score.toString())
    console.log('updateRecordScore is called, record=', score.toString());
  }

  updateRecordScore(score: number) {
    let promise = dataPreferences?.put('RecordScore', score.toString());
    promise?.then(() => {
      let promiseFlush = dataPreferences?.flush();
      promiseFlush?.then(() => {
        console.info(`updateRecordScore Succeeded in flush value of RecordScore`, `= `, score.toString());
      }).catch((err: BusinessError) => {
        console.error(`Failed to flush. code: ${err.code}, message: ${err.message}`);
      })
    }).catch((err: BusinessError) => {
      console.error(`Failed to put value of 'RecordScore'. code: ${err.code}, message: ${err.message}`);
    })
  }

  getPreferencesFromStorage(type: string = 'async'): preferences.Preferences | null {
    if (dataPreferences) {
      return dataPreferences;
    }

    if (type == 'sync') {
      return this.getPreferencesFromStorageSync();
    }

    let promise = preferences.getPreferences(this.context, "Game2048AppData");
    promise?.then((val: preferences.Preferences) => {
      console.info("Succeeded in getting preferences async. " + JSON.stringify(val));
      dataPreferences = val;
      return dataPreferences;
    }).catch((err: BusinessError) => {
      console.error(`Failed to get preferences. code: ${err.code}, message: ${err.message}`);
    })
    return dataPreferences;
  }

  getPreferencesFromStorageSync() {
    dataPreferences = preferences.getPreferencesSync(this.context, {
      name: "Game2048AppData"
    });
    console.info("Succeeded in getting preferences sync. " + JSON.stringify(dataPreferences));
    return dataPreferences;
  }

  saveValueToPreferences(key: string, value: string) {
    if (!dataPreferences) {
      this.getPreferencesFromStorage();
    }

    let promise = dataPreferences?.put(key, value);
    promise?.then(() => {
      let promiseFlush = dataPreferences?.flush();
      promiseFlush?.then(() => {
        console.info(`Succeeded in flush value of key`, key, `= `, value);
      }).catch((err: BusinessError) => {
        console.error(`Failed to flush. code: ${err.code}, message: ${err.message}`);
      })
    }).catch((err: BusinessError) => {
      console.error(`Failed to put value of 'RecordScore'. code: ${err.code}, message: ${err.message}`);
    })

  }

  getValueFromPreferences(key: string, defaultValue: string = '', type: string = 'async') {
    if (!dataPreferences) {
      this.getPreferencesFromStorage(type);
    }

    let promise = dataPreferences?.get(key, defaultValue);
    promise?.then((data: lang.ISendable) => {
      let dataStr = data as string;
      if (dataStr) {
        this.storage.set("RecordScore", parseInt(dataStr));
      } else {
        this.storage.set("RecordScore", 0);
      }
      console.info(`Succeeded in getting value of `, key, `- Data: ${dataStr}`);
    }).catch((err: BusinessError) => {
      console.error(`Failed to get value of `, key, `. code: ${err.code}, message: ${err.message}`);
    })
  }
}
