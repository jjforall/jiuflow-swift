import SwiftUI

struct ShopView: View {
    @EnvironmentObject var apiService: APIService
    @State private var products: [ShopProduct] = []
    @State private var isLoading = true
    @State private var selectedCategory: String? = nil

    let categories: [(String?, String)] = [
        (nil, "All"),
        ("gi", "Gi / 道衣"),
        ("rashguard", "Rashguard"),
        ("apparel", "Apparel"),
        ("goods", "Goods"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.1) { cat in
                        Button(cat.1) {
                            selectedCategory = cat.0
                            Task { await loadProducts() }
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(selectedCategory == cat.0 ? Color.jfRed : Color.jfCardBg)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                }
                .padding()
            }

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    // SWEEP partner banner
                    Link(destination: URL(string: "https://shop.sweep.love")!) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Official Partner")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Text("SWEEP / SIIIEEP\u{2122}")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Text("shop.sweep.love \u{2192}")
                                .font(.caption.bold())
                                .foregroundColor(.jfRed)
                        }
                        .padding()
                        .background(Color.jfCardBg)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(products) { product in
                            productCard(product)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.jfDarkBg)
        .navigationTitle("SJJJF Shop")
        .task { await loadProducts() }
    }

    func productCard(_ p: ShopProduct) -> some View {
        Link(destination: URL(string: "https://shop.sweep.love")!) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .fill(Color.jfCardBg)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.3))
                        )
                        .cornerRadius(12)
                    if p.isLimited {
                        Text("LIMITED")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.jfRed)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(8)
                    }
                }
                Text(p.displayName)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Text("\u{00a5}\(p.price_jpy)")
                        .font(.subheadline.bold())
                        .foregroundColor(.jfRed)
                    if let compare = p.compare_price_jpy {
                        Text("\u{00a5}\(compare)")
                            .font(.caption2)
                            .strikethrough()
                            .foregroundColor(.gray)
                    }
                }
                Text("Stock: \(p.stock)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }

    func loadProducts() async {
        isLoading = true
        products = (try? await apiService.getProducts(category: selectedCategory)) ?? []
        isLoading = false
    }
}
