# frozen_string_literal: true

require 'spec_helper'

describe 'pfreude_enc' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          python3_version: '3.10',
        )
      end
      let(:params) do
        {
          postgres_password: 'password',
        }
      end

      let(:pre_condition) { 'service { "puppetserver": }' }

      it { is_expected.to compile }
    end
  end
end
