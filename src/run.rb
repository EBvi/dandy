# encoding: utf-8

require 'net/http'
require 'uri'

# 기본 경로 설정
$home_dir = File.expand_path '~/.dandy'

# 선택 문장 가져오기
query_file = File.join $home_dir, 'query.txt'
query = File.read query_file

# 임시로 사용한 선택 문장을 담은 파일 삭제
File.delete query_file

# 부산대 맞춤법/문법 검사기 접속
uri = URI.parse File.read File.join $home_dir, 'uri.txt'

http = Net::HTTP.new uri.host, uri.port

request = Net::HTTP::Post.new uri.request_uri
request.set_form_data 'text1' => query

def change_uri
    uri = `curl --silent https://raw.githubusercontent.com/EBvi/dandy/master/src/uri.txt`
    if uri =~ /^http.*/im
        File.open((File.join $home_dir, 'uri.txt'), 'w') do |file|
            file.write uri
        end
    end
end

begin
    response = http.request request

    # 필요한 데이터만 뽑아 내기
    if response.body =~ /\s*<form id='formBugReport1'[^>]+>(.*)<\/form>/im
        source = ($1).force_encoding("utf-8")
    else
        source = "HTML 분석에 실패했습니다."
        # 네트워크 문제가 아니라 버전의 문제가 발생하는 경우도 있었다
        change_uri()
    end
rescue => e
    source = e.message
    # 여기에 도달했다면 서버나 네트워크 관련 문제일 가능성이 높다
    change_uri()
end

# 템플릿 파일 읽기
template_file = File.join $home_dir, 'template.html'
template = File.read template_file

# 템플릿 채우기
template.gsub! '{{source}}', source

# 최종 결과 파일에 쓰기
output_file = File.join $home_dir, 'output.html'
File.open(output_file, 'w') do |file|
    file.write template
end
