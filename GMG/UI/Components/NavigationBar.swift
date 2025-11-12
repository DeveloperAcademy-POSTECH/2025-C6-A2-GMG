//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct NavigationBar<Leading: View, Trailing: View>: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    @State var title: String
    @State private var isTitleEditing = false
    @FocusState private var isTitleFieldFocused: Bool

    let isBackButtonHidden: Bool
    let isTitleEditable: Bool
    let leading: Leading
    let trailing: Trailing
    let onEnterTitle: ((String) -> Void)?

    init(
        _ title: String? = nil,
        isBackButtonHidden: Bool = false,
        isTitleEditable: Bool = false,
        onEnterTitle: ((String) -> Void)? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title ?? ""
        self.isBackButtonHidden = isBackButtonHidden
        self.isTitleEditable = isTitleEditable
        self.onEnterTitle = onEnterTitle
        self.leading = leading()
        self.trailing = trailing()
    }

    func toggleTitleEditing() {
        guard isTitleEditable else { return }

        if isTitleEditing {
            finishEditingTitle()
            return
        }

        isTitleEditing = true
        DispatchQueue.main.async {
            isTitleFieldFocused = true
        }
    }

    func finishEditingTitle() {
        isTitleEditing = false
        isTitleFieldFocused = false
        onEnterTitle?(title)
    }

    var body: some View {
        HStack {
            if !isBackButtonHidden {
                BackButton()
            }

            leading

            Spacer()

            HStack(alignment: .center, spacing: 5) {
                Spacer()

                if isTitleEditing && isTitleEditable {
                    TextField("title", text: $title)
                        .multilineTextAlignment(.center)
                        .font(Typography.WantedSansStd.R6)
                        .foregroundStyle(
                            colorScheme == .light
                                ? Color.black1 : Color.white1
                        )
                        .focused($isTitleFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            finishEditingTitle()
                        }
                } else if isTitleEditable {
                    Text(title)
                        .font(Typography.WantedSansStd.R6)
                        .foregroundStyle(
                            colorScheme == .light
                                ? Color.black1 : Color.white1
                        )

                    Image(systemName: "pencil")
                } else {
                    Text(title)
                        .font(Typography.WantedSansStd.R6)
                        .foregroundStyle(
                            colorScheme == .light
                                ? Color.black1 : Color.white1
                        )
                }

                Spacer()
            }
            .onTapGesture {
                if isTitleEditable {
                    toggleTitleEditing()
                }
            }
            .frame(width: 177, height: 26)
            .background {
                if isTitleEditing {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            colorScheme == .light
                                ? Color.white3 : Color.black7
                        )
                }
            }

            Spacer()

            trailing
        }
        .padding(Spacing.md)
        .buttonStyle(NavigationBarButtonStyle())
        .onChange(of: isTitleFieldFocused, initial: false) { _, isFocused in
            guard !isFocused, isTitleEditing else { return }
            finishEditingTitle()
        }
    }
}

#Preview {
    NavigationBar("Test") {

    } trailing: {

    }
}
