//
//  LanguageTableViewController.swift
//  ARKitVision
//
//  Created by yongfu lu on 7/3/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import os.log

class LanguageTableViewController: UITableViewController {
    
    var tempCode : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.delegate = self
        tableView.dataSource = self
        
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print (SwiftGoogleTranslate.shared.result.count)
        return SwiftGoogleTranslate.shared.result.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       guard let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath) as? LanguageTableViewCell else { return UITableViewCell() }
              
        let language = SwiftGoogleTranslate.shared.result[indexPath.row]
              
        cell.languageLabel.text = language.language
        cell.codeLabel.text = language.name
      
              return cell
    }
    
    // When user click cell in this tableview
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //save the selected language to a tempCode, if user click "Done", change the targetLanguage, otherwise don't change anything
        tempCode = SwiftGoogleTranslate.shared.result[indexPath.row].language
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // change targetLanguageCode to the selected one. if user click "back", then this function will not be called.
       SwiftGoogleTranslate.shared.targetLanguageCode = self.tempCode ?? "en"
    }
    

   
    
   
   
}
