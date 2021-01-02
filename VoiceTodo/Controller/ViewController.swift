//
//  ViewController.swift
//  VoiceTodo
//
//  Created by 横井啓志 on 2020/12/31.
//

import UIKit
import Speech

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,SFSpeechRecognitionTaskDelegate, SFSpeechRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var speechImage: UIImageView!
    
    private var todoList = [String]()
    private var userDefaults = UserDefaults.standard
    //Speechのメンバプロパティ
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if let storedTodoList = userDefaults.array(forKey: "todoList") as? [String] {
            
            todoList.append(contentsOf: storedTodoList)
            
        }
        //ユーザーから録音許可が出たら、trueにする
//        textField.isUserInteractionEnabled = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        //認証チェックする
        SFSpeechRecognizer.requestAuthorization { (status) in
            
            OperationQueue.main.addOperation {
                switch status {
                case .authorized: //許可OK
                    print("許可OK")
                    self.speechImage.image = UIImage(named: "mike")
                case .denied: //拒否
                    print("拒否")
                    self.speechImage.image = UIImage(named: "noMike")
                case .restricted: //限定
                    print("限定")
                    self.speechImage.image = UIImage(named: "noMike")
                case .notDetermined: //不明
                    print("不明")
                    self.speechImage.image = UIImage(named: "noMike")
                @unknown default:
                    break
                }
            }
        }
        
        speechRecognizer?.delegate = self
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return todoList.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let todoTitle = todoList[indexPath.row]
        cell.textLabel?.text = todoTitle
        
        return cell
        
    }
    
    //削除メソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            todoList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            userDefaults.set(todoList, forKey: "todoList")
            
        }
        
    }
    
    @IBAction func send(_ sender: Any) {
        
        if textField.text == "" {
            return
        }
        
        if audioEngine.isRunning {
            //音声エンジンが動作中であれば停止
            audioEngine.stop()
            recognitionRequest?.endAudio()
            speechImage.image = UIImage(named: "mike")
            textField.text = ""
//            return
        }
        
        todoList.insert(textField.text!, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .right)
        userDefaults.set(todoList, forKey: "todoList")
        tableView.reloadData()
        textField.text = ""
        
    }
    
    
    //ここからSpeechメソッド
    
    private func startRecording() throws {
        //録音する処理
        if let recognitionTask = recognitionTask {
            //既存のタスクがあればキャンセル
            recognitionTask.cancel()
            self.recognitionTask = nil
        
        }
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.record)
        try audioSession.setMode(AVAudioSession.Mode.measurement)
        try audioSession.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("リクエスト生成エラー")
        }
        //録音完了前に途中の結果を報告してくれるプロパティ
        recognitionRequest.shouldReportPartialResults = true
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if let result = result {
                
                self.textField.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                
            }
            
            if error != nil || isFinal {
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.speechImage.image = UIImage(named: "mike")
                
            }
            
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare() //準備
        try audioEngine.start() //開始
        
        textField.text = "(認識中...そのまま話し続けてください)"
        
    }
    
    
    @IBAction func speechImageTapped(_ sender: Any) {
        
        print("録音ボタンタップしました")
        
        if audioEngine.isRunning {
            //音声エンジンが動作中であれば停止
            audioEngine.stop()
            recognitionRequest?.endAudio()
            speechImage.image = UIImage(named: "mike")
            textField.text = ""
            return
        }
        //録音開始
        try! startRecording()
        speechImage.image = UIImage(named: "audio")
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
        if available {
            
            speechImage.image = UIImage(named: "mike")
            
        }else {
            
            speechImage.image = UIImage(named: "noMike")
            
        }
        
    }
    
    
    
    

}

