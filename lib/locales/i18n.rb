# See https://ddnexus.github.io/pagy/api/frontend#i18n
# frozen_string_literal: true

# this file returns the default i18n hash used to replace the I18n gem

# flatten the dictionary file nested keys
# convert each value to a simple ruby interpolation proc
flatten = lambda do |hash, key=''|
            hash.each.reduce({}) do |h, (k, v)|
              if v.is_a?(Hash)
                h.merge!(flatten.call(v, "#{key}#{k}."))
              else
                v_proc = eval %({"#{key}#{k}" => lambda{|vars|"#{v.gsub(/%{[^}]+?}/){|m| "\#{vars[:#{m[2..-2]}]||'#{m}'}" }}"}}) #rubocop:disable Security/Eval
                h.merge!(v_proc)
              end
            end
          end


{}.tap do |i18n|
  i18n.define_singleton_method(:load) do |*args|  # ruby 1.9 compatible args
    args = [{locale: 'en'}] if args.empty?  # default
    self[:default_locale] = args[0][:locale]
    args.each do |arg|
      arg[:filepath]   ||= Pagy.root.join('locales', "#{arg[:locale]}.yml")
      arg[:pluralize]  ||= eval(Pagy.root.join('locales', 'plurals.rb').read)[arg[:locale]]   #rubocop:disable Security/Eval
      hash = YAML.load_file(arg[:filepath])
      hash.key?(arg[:locale]) or raise ArgumentError, %(I18N.load: :locale "#{arg[:locale]}" not found in :filepath "#{arg[:filepath]}")
      self[arg[:locale]] = [flatten.call(hash[arg[:locale]]), arg[:pluralize] ]
    end
  end
  i18n.load
end

