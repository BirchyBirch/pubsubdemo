import { Component, Inject, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
@Injectable()
export class MainDataService {
    constructor(private http: HttpClient, @Inject('BASE_URL') private baseUrl: string) {

    }
}
