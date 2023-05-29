//
//  ViewController.swift
//  ExtraLab3
//
//  Created by 楊皓麟 on 2023/5/27.
//

import UIKit
import AVFoundation
import AVKit

class videoApi : Codable{
    var result : result
}
class result : Codable{
    var audio : String
    var videoInfo : videoInfo
}
class videoInfo : Codable{
    var videourl : String
    var duration : Int
    var captionResult : captionResult
}
class captionResult: Codable{
    var results : [results]
}
class results : Codable{
    var captions:[captions]
}
class captions : Codable{
    var time : Int64
    var miniSecond: Double
    var content : String
}

var myVideoData : videoApi?

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playBtn: UIButton!
    
    var shouldUpdateScrollPosition = true
    var updateTimer: Timer?
    var previousIndex : IndexPath?
    var selectedIndexPath: IndexPath?
    var flag : Bool?
    var avPlayer:AVPlayer?
    var avpViewController = AVPlayerViewController()
    let sections = 0
    var rows = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewInit()
        getApi()
        tableView.reloadData()
    }
    
    @IBAction func playBtnClick(_ sender: Any) {
        guard flag != nil else{
            print("太急了，還沒獲取到api資料")
            return
        }
        if(avPlayer?.rate == 0){
            avPlayer?.play()
            playBtn.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }else{
            avPlayer?.pause()
            playBtn.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
    }
    
    
    func getApi(){
        let apiUrl = "https://api.italkutalk.com/api/video/detail"
        let url = URL(string: apiUrl)!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let json = ["guestKey": "44f6cfed-b251-4952-b6ab-34de1a599ae4",
                        "videoID": "5edfb3b04486bc1b20c2851a",
                        "mode": 0] as [String : Any]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request){ data, response, error in
            if(error != nil){
                print("發送失敗", error!.localizedDescription)
            }
            else{
                DispatchQueue.main.async {
                    do{
                        myVideoData = try JSONDecoder().decode(videoApi.self, from: data!)
                        print("獲取api資料成功")
                        self.tableView.reloadData()
                        self.flag = true
                        self.startVideo()
                        self.avPlayer?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] time in
                            self?.updateTableViewScrollPosition(for: time)
                        }
                    }catch{
                        print("錯誤！:\(error)")
                    }
                }
            }
        }
        task.resume()
    }

    func startVideo(){
        let url = URL(string: "https://itutbox.s3.amazonaws.com/youtubeMP4/Online/5ee07d2e4486bc1b20c535bf%5BFriday%20Joke%5D%20A%20Woman%20Gets%20On%20A%20Bus%20-%20YouTube.mp4.mp4")
        avPlayer = AVPlayer(url: url!)
        avpViewController.player = avPlayer
        avpViewController.view.frame.size.width = videoView.frame.size.width
        avpViewController.view.frame.size.height = videoView.frame.size.height
        self.videoView.addSubview(avpViewController.view)
    }
    
    func updateTableViewScrollPosition(for time: CMTime) {
        guard shouldUpdateScrollPosition else {
               return
           }
        let seconds = time.seconds
        print(seconds)
        var indexPath = IndexPath(row: rows, section: sections)// 根據秒數計算需要滾動到的 cell 的 indexPath
        for i in 0..<myVideoData!.result.videoInfo.captionResult.results[0].captions.count {
            if myVideoData!.result.videoInfo.captionResult.results[0].captions[i].miniSecond > seconds {
                rows = i - 1
                break
            }
            //當影片到達最後時，將最後的cell移到最上面
            if i == myVideoData!.result.videoInfo.captionResult.results[0].captions.count - 1{
                rows = i
            }
            //當影片播放到結束時，跳回第一個cell並且影片重新播放
            if seconds >= Double(myVideoData!.result.videoInfo.duration - 1){
                rows = 0
                avPlayer?.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                avPlayer?.play()
            }
        
        }
        indexPath = IndexPath(row: rows, section: sections)
        guard selectedIndexPath != indexPath else{
            return
        }
        tableView.reloadData()
        tableView.cellForRow(at: previousIndex ?? IndexPath(row: 0, section: 0))?.backgroundColor = UIColor.white
        tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor.gray
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        previousIndex = indexPath
    }
    
    func tableViewInit(){
        let cellNIB = UINib(nibName: "subTableViewCell", bundle: nil)
        tableView.register(cellNIB, forCellReuseIdentifier: "cell")
        print("tableView註冊完成!")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myVideoData?.result.videoInfo.captionResult.results[0].captions.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! subTableViewCell
        cell.setCell(sub: myVideoData?.result.videoInfo.captionResult.results[0].captions[indexPath.row].content ?? "無字幕", index: indexPath.row)
        if indexPath == previousIndex {
                cell.backgroundColor = UIColor.gray
            } else {
                cell.backgroundColor = UIColor.white
            }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        updateTimer?.invalidate()
            updateTimer = nil
            // 停止滾動位置的更新
            shouldUpdateScrollPosition = false
            // 啟動計時器，在兩秒後恢復滾動位置的更新
            updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                self?.shouldUpdateScrollPosition = true
            }
        
        let time = myVideoData?.result.videoInfo.captionResult.results[0].captions[indexPath.row].miniSecond ?? 0
        //time += 1
        let targetTime = CMTime(seconds: time, preferredTimescale: 1000)
        avPlayer?.seek(to: targetTime)
        avPlayer?.play()
        playBtn.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        tableView.reloadData()
        tableView.cellForRow(at: previousIndex ?? IndexPath(row: 0, section: 0))?.backgroundColor = UIColor.white
        tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor.gray
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        previousIndex = indexPath
    }
}
