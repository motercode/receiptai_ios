import Foundation
import UIKit
import MLXVLM
import MLXLMCommon

@MainActor
class MLXManager: ObservableObject {
    @Published var isReady = false
    @Published var isProcessing = false
    @Published var loadingProgress: String = ""
    @Published var responseText = ""

    private var modelContainer: ModelContainer?

    // MARK: - Load Model

    func loadModel() async {
        loadingProgress = "Descargando modelo DeepSeek-OCR…"
        do {
            let config = ModelConfiguration(id: "mlx-community/DeepSeek-OCR-2-4bit")
            let container = try await VLMModelFactory.shared.loadContainer(
                configuration: config
            ) { progress in
                Task { @MainActor in
                    let pct = Int(progress.fractionCompleted * 100)
                    self.loadingProgress = "Descargando modelo… \(pct)%"
                }
            }
            self.modelContainer = container
            self.isReady = true
            self.loadingProgress = ""
        } catch {
            self.loadingProgress = "Error al cargar el modelo: \(error.localizedDescription)"
        }
    }

    // MARK: - Process Receipt

    func processReceipt(image: UIImage) async {
        guard let container = modelContainer else { return }

        isProcessing = true
        responseText = ""

        // Shrink image to avoid Jetsam (OOM) terminations
        let safeImage = ImageHelper.resizeForMLX(image: image)

        let prompt = """
        Eres un experto contable. Analiza este recibo y extrae la información en formato JSON:
        { "comercio": "", "fecha": "", "total": 0.00, "items": [] }
        No añadas texto adicional. Responde solo con el JSON.
        """

        do {
            let result = try await container.perform { model, tokenizer, processor in
                let input = try await processor.prepare(
                    input: .init(
                        messages: [["role": "user", "content": prompt]],
                        images: .images([safeImage])
                    )
                )
                return try MLXLMCommon.generate(
                    input: input,
                    parameters: .init(temperature: 0.0),
                    context: .init(model: model, tokenizer: tokenizer)
                ) { _ in }
            }
            self.responseText = result.output
        } catch {
            self.responseText = "Error al procesar la imagen: \(error.localizedDescription)"
        }

        isProcessing = false
    }
}
