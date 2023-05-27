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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var label: UILabel!
    var avPlayer:AVPlayer?
    var playerItem:AVPlayerItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewInit()
        getApi()
        
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
                        print(myVideoData?.result.videoInfo.captionResult.results[0].captions[3].content ?? "")
                        self.tableView.reloadData()
                    }catch{
                        print("錯誤！:\(error)")
                    }
                }
            }
        }
        task.resume()
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
        return cell
    }
}

