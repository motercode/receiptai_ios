import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var mlxManager: MLXManager

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    modelStatusBanner

                    imagePicker

                    if let image = selectedImage {
                        receiptPreview(image: image)
                        scanButton
                    }

                    if mlxManager.isProcessing {
                        processingIndicator
                    }

                    if !mlxManager.responseText.isEmpty {
                        resultCard
                    }
                }
                .padding()
            }
            .navigationTitle("Recibos IA")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCamera) {
                CameraView(image: $selectedImage)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var modelStatusBanner: some View {
        if !mlxManager.isReady {
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text(mlxManager.loadingProgress.isEmpty
                     ? "Preparando modelo de IA…"
                     : mlxManager.loadingProgress)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        } else {
            Label("Modelo listo", systemImage: "checkmark.circle.fill")
                .font(.footnote.bold())
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var imagePicker: some View {
        HStack(spacing: 16) {
            // Camera
            Button {
                showCamera = true
            } label: {
                Label("Cámara", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!mlxManager.isReady)

            // Photo library
            PhotosPicker(selection: $selectedItem,
                         matching: .images,
                         photoLibrary: .shared()) {
                Label("Galería", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!mlxManager.isReady)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        mlxManager.responseText = ""
                    }
                }
            }
        }
    }

    private func receiptPreview(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator))
    }

    private var scanButton: some View {
        Button {
            guard let image = selectedImage else { return }
            Task { await mlxManager.processReceipt(image: image) }
        } label: {
            Label("Analizar Recibo", systemImage: "sparkle.magnifyingglass")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!mlxManager.isReady || mlxManager.isProcessing)
    }

    private var processingIndicator: some View {
        HStack(spacing: 12) {
            ProgressView().progressViewStyle(.circular)
            Text("Analizando recibo…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Resultado", systemImage: "doc.text.magnifyingglass")
                .font(.headline)

            Text(mlxManager.responseText)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Camera UIKit wrapper

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MLXManager())
}
