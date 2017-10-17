//
//  ViewController.swift
//  SmartCamera
//
//  Created by Nikola Majcen on 16/10/2017.
//  Copyright © 2017 Infinum. All rights reserved.
//

import UIKit
import AVKit
import CoreML
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var precisionLabel: UILabel!
    @IBOutlet weak var recognitionLabel: UILabel!

    var model: VNCoreMLModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeVideoCapture()
        initializeRecognitionModel()
    }

    private func initializeVideoCapture() {
        guard let captureDevice = AVCaptureDevice.default(for: .video),
            let captureInput = try? AVCaptureDeviceInput(device: captureDevice) else {
                showAlert(with: "Camera input is broken.")
                return
        }

        let captureSession = AVCaptureSession()

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.insertSublayer(previewLayer, at: 0)

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "outputQueue"))

        captureSession.addInput(captureInput)
        captureSession.addOutput(videoDataOutput)
        captureSession.startRunning()
    }

    private func initializeRecognitionModel() {
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {
            showAlert(with: "Problem with CoreML model.")
            return
        }
        self.model = model
    }

    private func showAlert(with message: String) {
        let alertController = UIAlertController(title: "Error occured", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    private func showResult(for object: String, with precision: Float) {
        self.recognitionLabel.text = object.capitalized
        self.precisionLabel.text = String(format: "%.2f%%", precision * 100)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let model = model else {
                return
        }

        let request = VNCoreMLRequest(model: model) { [weak self] (requestResult, error) in
            guard let results = requestResult.results as? [VNClassificationObservation], let bestResult = results.first else {
                return
            }

            DispatchQueue.main.async {
                self?.showResult(for: bestResult.identifier, with: bestResult.confidence)
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
