import { Component, Inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-fetch-data',
  templateUrl: './fetch-data.component.html'
})
export class FetchDataComponent {
  public forecasts: WeatherForecast[];

  constructor(private http: HttpClient, @Inject('BASE_URL') private baseUrl: string) {

    }
    public toSend: string;
    public SendHelloWorld() {
        this.http.post<string>(this.baseUrl + 'api/Demo/helloworld?message=' + this.toSend,null).subscribe(result => {
            console.log(result);
        }, error => console.error(error));
    }
    public PublishHelloWorld() {
        this.http.post<string>(this.baseUrl + 'api/Demo/helloworldpublish?message=' + this.toSend, null).subscribe(result => {
            console.log(result);
        }, error => console.error(error));
    }
}

interface WeatherForecast {
  dateFormatted: string;
  temperatureC: number;
  temperatureF: number;
  summary: string;
}
