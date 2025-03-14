import requests
import json
import time

class PushNotificationSender:
    def __init__(self):
        self.project_id = "push-5b79c"  # Substitua pelo seu Project ID
        self.access_token = "ya29.c.c0ASRK0Gb6cZOFhjC_alXSSxNOArIMtCYpmOEJ4J_goPWoXlqAXHHdBVccZxeG_NJYmIxpZQyISi3KDT0khsD43jaKvSwKEFthwAU7zHW9XhYHHSFRPiBKScC_KUpYO3hTYQmOEr7qTcNzD9pVjzv_fdEfrLQrcD0nsWo-s7SELd5G-Uxw_LTkGOBU7nM8YwfP01bc8RYCz7VcR9TlrLeF5mMveeiNzp8WePKQ2xXuRlIsAuhD0Ywey8GkSy6dE13X04vLTe0lIcSklbgnGYJdTTFQ3JaBou3n91e3iHrdI3oPsoFUnJ3S9NC2WzHr6fcJk6YBe2Hvppnnx30Hcm0TSCWUgyc0MuxBaChhVZPE769QWraGe0wQXA4CG385KwInUI1-l94rV0Z_isR7snuk67ga4rdurRnM2ie-8_IkFbB65erdoh-MIFOuIg6fuv57vYa0oa6yvQirm-Zf3hVsBY6nWtXWFfo5az3tWpqYbB2XvlZ-lUlpirRiVdQe6ytcyVd9Jx84dsU9Wqpa37cp-X51lR1o5I5Q6h-_janO0t5oOc1y885I7w2_BF9qdgn9mwUU0_0nYsf9Vyhgz0tBOxQUIp3V9SBXXqql2-WcWrJnU9W3yZv5FM2Q038Undi8hZ03fW2OUc2rzahp4h9m_oJMkOX1q4p_9Y8OX-pcQR7-zdqwaBl8qRocBrSXSBxFeQ8FIR06auMgpvltO19cSlvMyaoiucQIqVftb1_eati2klk2x-cUqWx1SvRoXqcq7R9cXYUZIvkFYba05wspgWV-vB2utMOwdVfw38ObfQyyRozMf0o6rrq0egJd2dvom6MXV0ms206rBdy8IO6icbMc6n9QsSX5l-2UilgObhzmqlWmOkmQh-atWimjn2qrxVZV2csZQigdfYm98nx5MBShz7tMvIf3p4o_WsbM3WMbrw53kpojmRU3x9hIsxrpR9p98V6w3Ud_mjbZrqn0R0_o_anvv5S90Z4cMZrfooJQfZ0WOs6W9Jq"  # Substitua pelo seu Access Token
        self.fcm_url = f"https://fcm.googleapis.com/v1/projects/{self.project_id}/messages:send"

    def send_notification(self, title, body, delay_in_seconds=0):
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {self.access_token}'
        }

        body_data = {
            "message": {
                "topic": "all",  # Envia para todos os dispositivos inscritos no tópico "all"
                "notification": {
                    "title": title,
                    "body": body
                }
            }
        }

        # Atraso opcional antes do envio
        if delay_in_seconds > 0:
            time.sleep(delay_in_seconds)

        try:
            response = requests.post(self.fcm_url, headers=headers, data=json.dumps(body_data))

            if response.status_code == 200:
                print("Notificação enviada com sucesso!")
                print("Resposta do FCM:", response.json())
            else:
                print(f"Erro ao enviar notificação: {response.status_code}")
                print("Resposta:", response.json())
        except Exception as e:
            print(f"Erro durante o envio da notificação: {e}")

# Teste
if __name__ == "__main__":
    sender = PushNotificationSender()

    # Configuração dos dados da notificação
    notification_title = "pelo python"
    notification_body = "Essa é uma mensagem de teste."
    delay_seconds = 5  # Envia após 5 segundos

    # Envia a notificação
    sender.send_notification(notification_title, notification_body, delay_seconds)
