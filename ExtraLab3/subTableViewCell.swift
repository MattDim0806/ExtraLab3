//
//  subTableViewCell.swift
//  ExtraLab3
//
//  Created by 楊皓麟 on 2023/5/27.
//

import UIKit

class subTableViewCell: UITableViewCell {

    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        //backgroundColor = UIColor.white
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCell(sub: String, index: Int){
        subLabel.text = sub
        indexLabel.text = String(index + 1)
    }
}
