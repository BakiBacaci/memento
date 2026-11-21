# Xcode projesine "Günün sözü" widget uzantısını, App Group yetkilerini ve
# gizlilik manifestini ekler.
#
# Neden script? Proje Windows'ta geliştiriliyor; Xcode'u açıp hedef eklemek
# mümkün değil. Codemagic (macOS) derlemeden önce bunu çalıştırıyor.
# Tekrar çalıştırmak güvenli: zaten eklenmişse hiçbir şey yapmaz.
#
#   cd ios && ruby scripts/add_widget_target.rb
require 'xcodeproj'

PROJECT   = File.expand_path('../Runner.xcodeproj', __dir__)
BUNDLE_ID = 'com.bakibacaci.memento'
WIDGET    = 'MementoWidget'

project = Xcodeproj::Project.open(PROJECT)
runner  = project.targets.find { |t| t.name == 'Runner' }
abort 'Runner hedefi bulunamadı' unless runner

# --- Runner: App Group yetkisi + gizlilik manifesti -------------------------
TEAM_ID = ENV['TEAM_ID']

runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  if TEAM_ID
    c.build_settings['DEVELOPMENT_TEAM'] = TEAM_ID
    c.build_settings['CODE_SIGN_STYLE']  = 'Automatic'
    c.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
    c.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
  end
end

runner_group = project.main_group.find_subpath('Runner', false)
unless runner_group.files.any? { |f| f.path == 'PrivacyInfo.xcprivacy' }
  ref = runner_group.new_reference('PrivacyInfo.xcprivacy')
  runner.add_resources([ref])
end
unless runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
  runner_group.new_reference('Runner.entitlements')
end

if project.targets.any? { |t| t.name == WIDGET }
  project.save
  puts 'Widget hedefi zaten var.'
  exit 0
end

# --- Widget uzantısı ---------------------------------------------------------
widget = project.new_target(:app_extension, WIDGET, :ios, '16.0')

group = project.main_group.find_subpath(WIDGET, true)
group.set_source_tree('<group>')
group.set_path(WIDGET)
swift = group.new_reference('MementoWidget.swift')
group.new_reference('Info.plist')
group.new_reference('MementoWidget.entitlements')
widget.add_file_references([swift])
widget.add_system_framework(%w[WidgetKit SwiftUI])

widget.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER']   = "#{BUNDLE_ID}.#{WIDGET}"
  s['PRODUCT_NAME']                = '$(TARGET_NAME)'
  s['INFOPLIST_FILE']              = "#{WIDGET}/Info.plist"
  s['CODE_SIGN_ENTITLEMENTS']      = "#{WIDGET}/MementoWidget.entitlements"
  s['SWIFT_VERSION']               = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET']  = '16.0'
  s['TARGETED_DEVICE_FAMILY']      = '1,2'
  s['SKIP_INSTALL']                = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS']     = ['$(inherited)', '@executable_path/Frameworks',
                                      '@executable_path/../../Frameworks']
  s['GENERATE_INFOPLIST_FILE']     = 'NO'
  s['CODE_SIGN_STYLE']             = 'Automatic'
  s['DEVELOPMENT_TEAM']            = TEAM_ID if TEAM_ID
end

# Sürüm numarası ana uygulamayla aynı olmalı, yoksa App Store reddeder:
# Flutter'ın ürettiği sürüm değişkenlerini xcconfig üzerinden al.
flutter_group = project.main_group.find_subpath('Flutter', false)
widget_xcconfig = flutter_group.files.find { |f| f.path == 'Widget.xcconfig' } ||
                  flutter_group.new_reference('Widget.xcconfig')
widget.build_configurations.each { |c| c.base_configuration_reference = widget_xcconfig }

# Uzantıyı uygulamanın içine göm.
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
build_file = embed.add_file_reference(widget.product_reference, true)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
runner.add_dependency(widget)

# "Thin Binary" / Flutter betikleri uzantıdan önce çalışmalı; gömme fazını
# sona taşıyarak döngüsel bağımlılık hatasını önle.
runner.build_phases.delete(embed)
runner.build_phases << embed

project.save
puts 'Widget hedefi eklendi.'
