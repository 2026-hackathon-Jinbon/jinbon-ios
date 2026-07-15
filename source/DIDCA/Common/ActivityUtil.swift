//
/*
 * Copyright 2025 JinBon.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
    
import UIKit

class ActivityUtil
{
    static func show(vc : UIViewController,
                     presentClosure : @escaping (() async throws -> Void),
                     completeClosure: @escaping(() -> Void),
                     failureCloseClosure: @escaping((_ title : String, _ message : String) -> Void))
    {
        let activity = Storyboard.popup.instance.instantiateViewController(withIdentifier: ViewControllerID.activityIndicator.rawValue) as! ActivityIndicatorViewController
        
        activity.modalPresentationStyle = .overCurrentContext
        
        activity.presentClosure = presentClosure
        activity.completeClosure = completeClosure
        activity.failureClosure = failureCloseClosure

        DispatchQueue.main.async
        {
            vc.present(activity, animated: false, completion: nil)
        }
    }
    
}

