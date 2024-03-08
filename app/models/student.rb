require "open-uri"

class Student < ApplicationRecord
  after_save if: -> { saved_change_to_name? || saved_change_to_bio? } do
    set_funny_nickname
    set_photo
  end

  has_one_attached :photo

  def funny_nickname
    if super.blank?
      set_funny_nickname
    else
      super
    end
  end

  def set_funny_nickname
    Rails.cache.fetch("#{cache_key_with_version}/content") do
      client = OpenAI::Client.new
        chaptgpt_response = client.chat(parameters: {
          model: "gpt-3.5-turbo",
          messages: [{ role: "user", content: "Give me a short funny nickname for #{name} that has something to do with #{bio}. Give me only the nickname, without any of your own answers like 'Here is a simple nickname'."}]
        })
        new_nickname = chaptgpt_response["choices"][0]["message"]["content"]
        update(funny_nickname: new_nickname)
        return new_nickname
    end
  end

  private

  def set_photo
    client = OpenAI::Client.new
    response = client.images.generate(parameters: {
      prompt: "An image of this student: #{name} as a cartoon for children", size: "256x256"
    })

    url = response["data"][0]["url"]
    file =  URI.open(url)

    photo.purge if photo.attached?
    photo.attach(io: file, filename: "ai_generated_image.png", content_type: "image/png")
    return photo
  end
end
