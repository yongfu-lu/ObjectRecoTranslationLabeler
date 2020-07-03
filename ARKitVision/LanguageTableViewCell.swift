//
//  LanguageTableViewCell.swift
//  ARKitVision
//
//  Created by yongfu lu on 7/3/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class LanguageTableViewCell: UITableViewCell {
    
    //MARK: PROPERTIES
    
    @IBOutlet weak var languageLabel: UILabel!
    
    @IBOutlet weak var codeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
