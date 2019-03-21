//
//  MainViewController.swift
//  RunchKin
//
//  Created by Madison Waters on 3/19/19.
//  Copyright © 2019 Jonah Bergevin. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MainViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var gifView: UIImageView!
    @IBOutlet weak var viewBlock: UIView!
    @IBOutlet weak var runButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewBlock.layer.addBorder(edge: .top, color: lightGray!, thickness: 10)
        viewBlock.layer.addBorder(edge: .top, color: salmon!, thickness: 5)
        
        gifView.loadGif(name: "running")
        viewBlock.backgroundColor = navy
        runButton.backgroundColor = green
        runButton.layer.cornerRadius = runButton.frame.size.width / 2
            
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation // ShowNewRunVC

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
